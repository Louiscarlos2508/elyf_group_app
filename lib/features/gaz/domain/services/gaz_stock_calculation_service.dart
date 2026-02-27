import 'dart:math';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/gaz_settings.dart';
import '../entities/stock_transfer.dart';
import '../../../../features/administration/domain/entities/enterprise.dart';

class StockMetrics {
  final Map<int, int> fullByWeight;
  final Map<int, int> emptyByWeight;
  final Map<int, int> issueByWeight;
  final Map<int, int> centralizedByWeight;
  final int activePointsOfSaleCount;
  final int totalPointsOfSaleCount;
  final List<int> availableWeights;
  final Map<
    int,
    ({int full, int empty, int inTransit, int defective, int leak})
  >
  stockByCapacity;
  final Map<String, int> transitBreakdown;

  int get totalFull => fullByWeight.values.fold<int>(0, (sum, v) => sum + v);
  int get totalEmpty => emptyByWeight.values.fold<int>(0, (sum, v) => sum + v);
  int get totalCentralized =>
      centralizedByWeight.values.fold<int>(0, (sum, v) => sum + v);
  int get totalIssues => issueByWeight.values.fold<int>(0, (sum, v) => sum + v);

  String get fullSummary =>
      GazStockCalculationService.formatStockByWeightSummary(
        fullByWeight,
        availableWeights,
      );
  String get emptySummary =>
      GazStockCalculationService.formatStockByWeightSummary(
        emptyByWeight,
        availableWeights,
      );
  String get issueSummary =>
      GazStockCalculationService.formatStockByWeightSummary(
        issueByWeight,
        availableWeights,
      );
  String get centralizedSummary =>
      GazStockCalculationService.formatStockByWeightSummary(
        centralizedByWeight,
        availableWeights,
      );

  StockMetrics({
    required this.fullByWeight,
    required this.emptyByWeight,
    required this.issueByWeight,
    required this.centralizedByWeight,
    required this.activePointsOfSaleCount,
    required this.totalPointsOfSaleCount,
    required this.availableWeights,
    required this.stockByCapacity,
    required this.transitBreakdown,
  });
}

class PointOfSaleStockMetrics {
  final String pointOfSaleId;
  final int totalFull;
  final int totalEmpty;
  final int totalInTransit;
  final int totalIssues;
  final Map<
    int,
    ({int full, int empty, int inTransit, int defective, int leak})
  >
  stockByCapacity;

  PointOfSaleStockMetrics({
    required this.pointOfSaleId,
    required this.totalFull,
    required this.totalEmpty,
    required this.totalInTransit,
    required this.totalIssues,
    required this.stockByCapacity,
  });
}

class GazStockCalculationService {
  GazStockCalculationService._();

  static List<CylinderStock> filterFullStocks(List<CylinderStock> stocks) {
    return stocks.where((s) => s.status == CylinderStatus.full).toList();
  }

  static List<CylinderStock> filterEmptyStocks(List<CylinderStock> stocks) {
    return stocks
        .where((s) => s.status == CylinderStatus.emptyAtStore)
        .toList();
  }

  static List<CylinderStock> filterIssueStocks(List<CylinderStock> stocks) {
    return stocks
        .where(
          (s) =>
              s.status == CylinderStatus.defective ||
              s.status == CylinderStatus.leak ||
              s.status == CylinderStatus.leakInTransit,
        )
        .toList();
  }

  static int calculateTotalFullCylinders(List<CylinderStock> stocks) {
    return filterFullStocks(stocks).fold<int>(0, (sum, s) => sum + s.quantity);
  }

  static int calculateTotalEmptyCylinders(List<CylinderStock> stocks) {
    return filterEmptyStocks(stocks).fold<int>(0, (sum, s) => sum + s.quantity);
  }

  static Map<int, int> groupStocksByWeight(List<CylinderStock> stocks) {
    final byWeight = <int, int>{};
    for (final stock in stocks) {
      byWeight[stock.weight] = (byWeight[stock.weight] ?? 0) + stock.quantity;
    }
    return byWeight;
  }

  static StockMetrics calculateStockMetrics({
    required List<CylinderStock> stocks,
    required List<Enterprise> pointsOfSale,
    required List<Cylinder> cylinders,
    List<StockTransfer>? transfers,
    GazSettings? settings,
    String? targetEnterpriseId,
    bool isPOS = false,
  }) {
    final cylinderIds = cylinders.map((c) => c.id).toSet();
    final validStocks = stocks
        .where((s) => cylinderIds.contains(s.cylinderId))
        .toList();

    // FIX: If this is a POS, we must ONLY consider its own stocks!
    final relevantStocks = isPOS && targetEnterpriseId != null
        ? validStocks
              .where((s) => s.enterpriseId == targetEnterpriseId)
              .toList()
        : validStocks;

    final fullStocks = filterFullStocks(relevantStocks);
    final emptyStocks = filterEmptyStocks(relevantStocks);
    final issueStocks = filterIssueStocks(relevantStocks);

    final fullByWeight = groupStocksByWeight(fullStocks);
    final emptyByWeight = groupStocksByWeight(emptyStocks);
    final issueByWeight = groupStocksByWeight(issueStocks);

    final inTransitStocks = relevantStocks
        .where((s) => s.status == CylinderStatus.emptyInTransit)
        .toList();
    final inTransitByWeight = groupStocksByWeight(inTransitStocks);
    final centralizedByWeight = <int, int>{};
    final transitBreakdown = <String, int>{};

    for (final s in inTransitStocks) {
      final enterprise = pointsOfSale
          .where((p) => p.id == s.enterpriseId)
          .firstOrNull;
      final name =
          enterprise?.name ??
          (s.enterpriseId == targetEnterpriseId ? 'Local (Tournées)' : 'Autre');
      transitBreakdown[name] = (transitBreakdown[name] ?? 0) + s.quantity;
    }

    if (transfers != null) {
      // FIX: If isPOS, only incoming shipped transfers should count as transit!
      final relevantTransfers = isPOS && targetEnterpriseId != null
          ? transfers.where(
              (t) =>
                  t.status == StockTransferStatus.shipped &&
                  t.toEnterpriseId == targetEnterpriseId,
            )
          : transfers.where(
              (t) =>
                  t.status == StockTransferStatus.shipped &&
                  (t.toEnterpriseId == targetEnterpriseId ||
                      t.fromEnterpriseId == targetEnterpriseId),
            );

      for (final t in relevantTransfers) {
        final qty = t.items.fold<int>(0, (sum, i) => sum + i.quantity);
        final label = 'Transfert #${t.id.substring(0, min(8, t.id.length))}';
        transitBreakdown[label] = (transitBreakdown[label] ?? 0) + qty;
      }
    }

    final isMother = !isPOS;

    for (final cylinder in cylinders) {
      final weight = cylinder.weight;

      int totalInTransit = inTransitByWeight[weight] ?? 0;
      if (transfers != null) {
        final relevantTransfers = isPOS && targetEnterpriseId != null
            ? transfers.where(
                (t) =>
                    t.status == StockTransferStatus.shipped &&
                    t.toEnterpriseId == targetEnterpriseId,
              )
            : transfers.where(
                (t) =>
                    t.status == StockTransferStatus.shipped &&
                    (t.toEnterpriseId == targetEnterpriseId ||
                        t.fromEnterpriseId == targetEnterpriseId),
              );

        final shippedQty = relevantTransfers
            .expand((t) => t.items)
            .where((item) => item.weight == weight)
            .fold<int>(0, (sum, item) => sum + item.quantity);
        totalInTransit += shippedQty;
      }

      if (totalInTransit > 0) {
        centralizedByWeight[weight] = totalInTransit;
      }
    }

    final activePointsOfSale = pointsOfSale.where((p) => p.isActive).toList();

    final weightsToShow = cylinders.map((c) => c.weight).toSet().toList()
      ..sort();

    final stockByCapacity =
        <
          int,
          ({int full, int empty, int inTransit, int defective, int leak})
        >{};
    for (final weight in weightsToShow) {
      final full = fullByWeight[weight] ?? 0;
      final empty = emptyByWeight[weight] ?? 0;
      final inTransit = centralizedByWeight[weight] ?? 0;

      final defective = issueStocks
          .where(
            (s) => s.weight == weight && s.status == CylinderStatus.defective,
          )
          .fold<int>(0, (sum, s) => sum + s.quantity);
      final leaks = issueStocks
          .where(
            (s) =>
                s.weight == weight &&
                (s.status == CylinderStatus.leak ||
                    s.status == CylinderStatus.leakInTransit),
          )
          .fold<int>(0, (sum, s) => sum + s.quantity);

      stockByCapacity[weight] = (
        full: full,
        empty: empty,
        inTransit: inTransit,
        defective: defective,
        leak: leaks,
      );
    }

    return StockMetrics(
      fullByWeight: fullByWeight,
      emptyByWeight: emptyByWeight,
      issueByWeight: issueByWeight,
      centralizedByWeight: centralizedByWeight,
      activePointsOfSaleCount: activePointsOfSale.length,
      totalPointsOfSaleCount: pointsOfSale.length,
      availableWeights: weightsToShow,
      stockByCapacity: stockByCapacity,
      transitBreakdown: transitBreakdown,
    );
  }

  static PointOfSaleStockMetrics calculatePosStockMetrics({
    required String enterpriseId,
    String? siteId,
    required List<CylinderStock> allStocks,
    List<StockTransfer>? transfers,
    List<Cylinder>? cylinders,
  }) {
    final List<CylinderStock> validStocks;
    if (cylinders != null) {
      final cylinderIds = cylinders.map((c) => c.id).toSet();
      validStocks = allStocks
          .where((s) => cylinderIds.contains(s.cylinderId))
          .toList();
    } else {
      validStocks = allStocks;
    }

    final posStocks = validStocks
        .where(
          (s) =>
              s.enterpriseId == enterpriseId &&
              (siteId == null || s.siteId == siteId),
        )
        .toList();

    final fullStocks = posStocks
        .where((s) => s.status == CylinderStatus.full)
        .toList();
    final emptyAtStoreStocks = posStocks
        .where((s) => s.status == CylinderStatus.emptyAtStore)
        .toList();
    final emptyInTransitStocks = posStocks
        .where((s) => s.status == CylinderStatus.emptyInTransit)
        .toList();

    final fullByWeight = groupStocksByWeight(fullStocks);
    final emptyAtStoreByWeight = groupStocksByWeight(emptyAtStoreStocks);
    final emptyInTransitByWeight = groupStocksByWeight(emptyInTransitStocks);

    final issueStocks = posStocks
        .where(
          (s) =>
              s.status == CylinderStatus.defective ||
              s.status == CylinderStatus.leak ||
              s.status == CylinderStatus.leakInTransit,
        )
        .toList();
    final issueByWeight = groupStocksByWeight(issueStocks);

    final totalFull = fullByWeight.values.fold<int>(0, (sum, v) => sum + v);
    final totalEmpty = emptyAtStoreByWeight.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );

    final Map<int, int> realInTransitByWeight = Map.from(
      emptyInTransitByWeight,
    );
    if (transfers != null) {
      final incomingShipped = transfers
          .where(
            (t) =>
                t.toEnterpriseId == enterpriseId &&
                t.status == StockTransferStatus.shipped,
          )
          .toList();
      for (final transfer in incomingShipped) {
        for (final item in transfer.items) {
          realInTransitByWeight[item.weight] =
              (realInTransitByWeight[item.weight] ?? 0) + item.quantity;
        }
      }
    }

    final totalInTransit = realInTransitByWeight.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );
    final totalIssues = issueByWeight.values.fold<int>(0, (sum, v) => sum + v);

    final Set<int> weightSet = cylinders != null
        ? cylinders.map((c) => c.weight).toSet()
        : posStocks.map((s) => s.weight).toSet();
    final weightsToShow = weightSet.toList()..sort();

    final stockByCapacity =
        <
          int,
          ({int full, int empty, int inTransit, int defective, int leak})
        >{};

    for (final weight in weightsToShow) {
      final full = fullByWeight[weight] ?? 0;
      final empty = emptyAtStoreByWeight[weight] ?? 0;
      final inTransit = realInTransitByWeight[weight] ?? 0;
      final defective = posStocks
          .where(
            (s) => s.weight == weight && s.status == CylinderStatus.defective,
          )
          .fold<int>(0, (sum, s) => sum + s.quantity);
      final leaks = posStocks
          .where(
            (s) =>
                s.weight == weight &&
                (s.status == CylinderStatus.leak ||
                    s.status == CylinderStatus.leakInTransit),
          )
          .fold<int>(0, (sum, s) => sum + s.quantity);

      stockByCapacity[weight] = (
        full: full,
        empty: empty,
        inTransit: inTransit,
        defective: defective,
        leak: leaks,
      );
    }

    return PointOfSaleStockMetrics(
      pointOfSaleId: enterpriseId,
      totalFull: totalFull,
      totalEmpty: totalEmpty,
      totalInTransit: totalInTransit,
      totalIssues: totalIssues,
      stockByCapacity: stockByCapacity,
    );
  }

  static String formatStockByWeightSummary(
    Map<int, int> stockByWeight,
    List<int> weights,
  ) {
    if (weights.isEmpty) {
      return 'Aucune bouteille';
    }
    return weights.map((w) => '${w}kg: ${stockByWeight[w] ?? 0}').join(' • ');
  }
}

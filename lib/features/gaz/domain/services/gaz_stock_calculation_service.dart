import 'dart:math';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/gaz_settings.dart';
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
        .where((s) => s.status == CylinderStatus.emptyAtStore || s.status == CylinderStatus.emptyInTransit)
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
    return filterFullStocks(stocks).fold<int>(0, (sum, s) => sum + s.quantity.toInt());
  }

  static int calculateTotalEmptyCylinders(List<CylinderStock> stocks) {
    return filterEmptyStocks(stocks).fold<int>(0, (sum, s) => sum + s.quantity.toInt());
  }

  static Map<int, int> groupStocksByWeight(List<CylinderStock> stocks) {
    final byWeight = <int, int>{};
    for (final stock in stocks) {
      byWeight[stock.weight] = (byWeight[stock.weight] ?? 0) + stock.quantity.toInt();
    }
    return byWeight;
  }

  static StockMetrics calculateStockMetrics({
    required List<CylinderStock> stocks,
    required List<Enterprise> pointsOfSale,
    required List<Cylinder> cylinders,
    GazSettings? settings,
    String? targetEnterpriseId,
    bool isPOS = false,
  }) {
    final cylinderIds = cylinders.map((c) => c.id).toSet();
    final validStocks = stocks
        .where((s) => cylinderIds.contains(s.cylinderId))
        .toList();

    final relevantStocks = isPOS && targetEnterpriseId != null
        ? validStocks
              .where((s) => s.enterpriseId == targetEnterpriseId)
              .toList()
        : validStocks;

    // 1. Base weight-based Maps (Exhaustive)
    final fullByWeight = <int, int>{};
    final emptyByWeight = <int, int>{};
    final issueByWeight = <int, int>{};
    final centralizedByWeight = <int, int>{};
    final transitBreakdown = <String, int>{};

    for (final cylinder in cylinders) {
      final w = cylinder.weight;
      final cId = cylinder.id;
      
      final sFull = relevantStocks.where((s) => s.cylinderId == cId && s.status == CylinderStatus.full).fold<int>(0, (sum, s) => sum + s.quantity.toInt());
      fullByWeight[w] = (fullByWeight[w] ?? 0) + sFull;

      // Empty = physical empty (store + tour)
      final sEmpty = relevantStocks.where((s) => s.cylinderId == cId && (s.status == CylinderStatus.emptyAtStore || s.status == CylinderStatus.emptyInTransit)).fold<int>(0, (sum, s) => sum + s.quantity.toInt());
      emptyByWeight[w] = (emptyByWeight[w] ?? 0) + sEmpty;

      // Issues = physical issues (leak + tour_leak + defective)
      final sIssues = relevantStocks.where((s) => s.cylinderId == cId && (s.status == CylinderStatus.leak || s.status == CylinderStatus.leakInTransit || s.status == CylinderStatus.defective)).fold<int>(0, (sum, s) => sum + s.quantity.toInt());
      issueByWeight[w] = (issueByWeight[w] ?? 0) + sIssues;

      // Transit = Tours
      final sTransit = relevantStocks
          .where((s) => s.cylinderId == cId && (s.status == CylinderStatus.emptyInTransit || s.status == CylinderStatus.leakInTransit))
          .fold<int>(0, (sum, s) => sum + s.quantity.toInt());
      if (sTransit > 0) {
        centralizedByWeight[w] = (centralizedByWeight[w] ?? 0) + sTransit;
      }
    }

    // Transit Breakdown for Details
    final localTransitStocks = relevantStocks.where((s) => s.status == CylinderStatus.emptyInTransit || s.status == CylinderStatus.leakInTransit);
    for (final s in localTransitStocks) {
      final name = pointsOfSale.where((p) => p.id == s.enterpriseId).firstOrNull?.name ?? 
                  (s.enterpriseId == targetEnterpriseId ? 'Local (Tournées)' : 'Chargement');
      transitBreakdown[name] = (transitBreakdown[name] ?? 0) + s.quantity.toInt();
    }
    // Points of Sale breakdown

    final weightsToShow = cylinders.map((c) => c.weight).toSet().toList()..sort();
    final stockByCapacity = <int, ({int full, int empty, int inTransit, int defective, int leak})>{};
    for (final weight in weightsToShow) {
      stockByCapacity[weight] = (
        full: fullByWeight[weight] ?? 0,
        empty: emptyByWeight[weight] ?? 0,
        inTransit: centralizedByWeight[weight] ?? 0,
        defective: relevantStocks.where((s) => s.weight == weight && s.status == CylinderStatus.defective).fold<int>(0, (sum, s) => sum + s.quantity.toInt()),
        leak: relevantStocks.where((s) => s.weight == weight && (s.status == CylinderStatus.leak || s.status == CylinderStatus.leakInTransit)).fold<int>(0, (sum, s) => sum + s.quantity.toInt()),
      );
    }

    final activePointsOfSaleCount = pointsOfSale.where((p) => p.isActive).length;

    return StockMetrics(
      fullByWeight: fullByWeight,
      emptyByWeight: emptyByWeight,
      issueByWeight: issueByWeight,
      centralizedByWeight: centralizedByWeight,
      activePointsOfSaleCount: activePointsOfSaleCount,
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
          .fold<int>(0, (sum, s) => sum + s.quantity.toInt());
      final leaks = posStocks
          .where(
            (s) =>
                s.weight == weight &&
                (s.status == CylinderStatus.leak ||
                    s.status == CylinderStatus.leakInTransit),
          )
          .fold<int>(0, (sum, s) => sum + s.quantity.toInt());

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

  /// Calcule l'inventaire de conservation du parc bouteilles.
  ///
  /// Invariant : registeredTotal = Pleines + Vides + Problèmes (Fuites/Déf.) + Transit
  ///
  /// [cylinders]   : types de cylindres avec leur registeredTotal
  /// [allStocks]   : tous les CylinderStock (dépôt + POS) de l'entreprise et ses enfants
  static BottleConservationResult calculateConservation({
    required List<Cylinder> cylinders,
    required List<CylinderStock> allStocks,
  }) {
    final items = <BottleConservationItem>[];

    for (final cylinder in cylinders) {
      final w = cylinder.weight;
      final registered = cylinder.registeredTotal;

      final cId = cylinder.id;

      // PIVOT: Filtrer par cylinderId pour la précision absolue
      final relatedStocks = allStocks.where((s) => s.cylinderId == cId);

      // 1. Pleines (Magasin/POS + Transit inter-site)
      final totalFull = relatedStocks
          .where((s) => s.status == CylinderStatus.full)
          .fold<int>(0, (sum, s) => sum + s.quantity.toInt());
          
      // 2. Vides (Magasin/POS + Tournées + Transit inter-site)
      final totalEmpty = relatedStocks
          .where((s) => s.status == CylinderStatus.emptyAtStore || s.status == CylinderStatus.emptyInTransit)
          .fold<int>(0, (sum, s) => sum + s.quantity.toInt());

      final totalIssues = relatedStocks
          .where((s) => 
            s.status == CylinderStatus.leak || 
            s.status == CylinderStatus.leakInTransit || 
            s.status == CylinderStatus.defective
          )
          .fold<int>(0, (sum, s) => sum + s.quantity.toInt());

      final totalAccounted = totalFull + totalEmpty + totalIssues;
      final discrepancy = registered > 0 ? registered - totalAccounted : 0;

      items.add(BottleConservationItem(
        weight: w,
        registeredTotal: registered,
        full: totalFull,
        empty: totalEmpty,
        issues: totalIssues,
        discrepancy: discrepancy,
      ));
    }

    items.sort((a, b) => a.weight.compareTo(b.weight));
    return BottleConservationResult(items: items);
  }
}

// ---------------------------------------------------------------------------
// Modèle de conservation du parc bouteilles
// ---------------------------------------------------------------------------

/// Résultat de conservation pour un type de cylindre.
class BottleConservationItem {
  const BottleConservationItem({
    required this.weight,
    required this.registeredTotal,
    required this.full,
    required this.empty,
    required this.issues,
    required this.discrepancy,
  });

  final int weight;
  final int registeredTotal; // Parc déclaré
  final int full;             // Total Pleines (Dépôt + POS + Transferts)
  final int empty;            // Total Vides (Dépôt + POS + Tours + Transferts)
  final int issues;           // Total Problèmes (Fuites + Défectueuses + Transferts)
  final int discrepancy;      // Écart (>0 = perte, <0 = surplus)

  int get accounted => full + empty + issues;
  bool get hasDiscrepancy => registeredTotal > 0 && discrepancy != 0;
  bool get isTracked => registeredTotal > 0;

  double get discrepancyPercent =>
      registeredTotal > 0 ? (discrepancy.abs() / registeredTotal * 100) : 0;
}

/// Résultat global de conservation du parc.
class BottleConservationResult {
  const BottleConservationResult({required this.items});

  final List<BottleConservationItem> items;

  bool get hasAnyDiscrepancy => items.any((i) => i.hasDiscrepancy);
  bool get isFullyTracked => items.every((i) => i.isTracked);
  List<BottleConservationItem> get discrepancies =>
      items.where((i) => i.hasDiscrepancy).toList();
}



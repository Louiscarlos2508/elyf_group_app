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

    final relevantStocks = isPOS && targetEnterpriseId != null
        ? validStocks
              .where((s) => s.enterpriseId == targetEnterpriseId)
              .toList()
        : validStocks;

    // 1. Collect all inter-site shipped items
    final shippedTransfers = (transfers ?? []).where((t) => t.status == StockTransferStatus.shipped);
    final interSiteItems = isPOS && targetEnterpriseId != null
        ? shippedTransfers.where((t) => t.toEnterpriseId == targetEnterpriseId).expand((t) => t.items).toList()
        : shippedTransfers.expand((t) => t.items).toList();

    // 2. Base weight-based Maps (Exhaustive)
    final fullByWeight = <int, int>{};
    final emptyByWeight = <int, int>{};
    final issueByWeight = <int, int>{};
    final centralizedByWeight = <int, int>{};
    final transitBreakdown = <String, int>{};

    for (final cylinder in cylinders) {
      final w = cylinder.weight;
      final cId = cylinder.id;
      
      // Full = physical full + inter-site full
      // PIVOT: Filtrer par cylinderId pour la résilience pour les stocks physiques
      final sFull = relevantStocks.where((s) => s.cylinderId == cId && s.status == CylinderStatus.full).fold<int>(0, (sum, s) => sum + s.quantity);
      // NOTE: Les transferts n'ont pas de cylinderId, on utilise le poids
      final tFull = interSiteItems.where((i) => i.weight == w && i.status == CylinderStatus.full).fold<int>(0, (sum, i) => sum + i.quantity);
      fullByWeight[w] = (fullByWeight[w] ?? 0) + sFull + tFull;

      // Empty = physical empty (store + tour) + inter-site empty
      final sEmpty = relevantStocks.where((s) => s.cylinderId == cId && (s.status == CylinderStatus.emptyAtStore || s.status == CylinderStatus.emptyInTransit)).fold<int>(0, (sum, s) => sum + s.quantity);
      final tEmpty = interSiteItems.where((i) => i.weight == w && (i.status == CylinderStatus.emptyAtStore || i.status == CylinderStatus.emptyInTransit)).fold<int>(0, (sum, i) => sum + i.quantity);
      emptyByWeight[w] = (emptyByWeight[w] ?? 0) + sEmpty + tEmpty;

      // Issues = physical issues (leak + tour_leak + defective) + inter-site issues
      final sIssues = relevantStocks.where((s) => s.cylinderId == cId && (s.status == CylinderStatus.leak || s.status == CylinderStatus.leakInTransit || s.status == CylinderStatus.defective)).fold<int>(0, (sum, s) => sum + s.quantity);
      final tIssues = interSiteItems.where((i) => i.weight == w && (i.status == CylinderStatus.leak || i.status == CylinderStatus.leakInTransit || i.status == CylinderStatus.defective)).fold<int>(0, (sum, i) => sum + i.quantity);
      issueByWeight[w] = (issueByWeight[w] ?? 0) + sIssues + tIssues;

      // Transit = Tours + Inter-site
      final sTransit = relevantStocks.where((s) => s.cylinderId == cId && (s.status == CylinderStatus.emptyInTransit || s.status == CylinderStatus.leakInTransit)).fold<int>(0, (sum, s) => sum + s.quantity);
      final tTransit = interSiteItems.where((i) => i.weight == w).fold<int>(0, (sum, i) => sum + i.quantity);
      if (sTransit + tTransit > 0) {
        centralizedByWeight[w] = (centralizedByWeight[w] ?? 0) + sTransit + tTransit;
      }
    }

    // Transit Breakdown for Details
    final localTransitStocks = relevantStocks.where((s) => s.status == CylinderStatus.emptyInTransit || s.status == CylinderStatus.leakInTransit);
    for (final s in localTransitStocks) {
      final name = pointsOfSale.where((p) => p.id == s.enterpriseId).firstOrNull?.name ?? 
                  (s.enterpriseId == targetEnterpriseId ? 'Local (Tournées)' : 'Chargement');
      transitBreakdown[name] = (transitBreakdown[name] ?? 0) + s.quantity;
    }
    for (final t in shippedTransfers) {
      if (isPOS && targetEnterpriseId != null && t.toEnterpriseId != targetEnterpriseId) continue;
      final qty = t.items.fold<int>(0, (sum, i) => sum + i.quantity);
      final label = 'Transfert #${t.id.substring(0, min(8, t.id.length))}';
      transitBreakdown[label] = (transitBreakdown[label] ?? 0) + qty;
    }

    final weightsToShow = cylinders.map((c) => c.weight).toSet().toList()..sort();
    final stockByCapacity = <int, ({int full, int empty, int inTransit, int defective, int leak})>{};
    for (final weight in weightsToShow) {
      stockByCapacity[weight] = (
        full: fullByWeight[weight] ?? 0,
        empty: emptyByWeight[weight] ?? 0,
        inTransit: centralizedByWeight[weight] ?? 0,
        defective: relevantStocks.where((s) => s.weight == weight && s.status == CylinderStatus.defective).fold<int>(0, (sum, s) => sum + s.quantity) +
                  interSiteItems.where((i) => i.weight == weight && i.status == CylinderStatus.defective).fold<int>(0, (sum, i) => sum + i.quantity),
        leak: relevantStocks.where((s) => s.weight == weight && (s.status == CylinderStatus.leak || s.status == CylinderStatus.leakInTransit)).fold<int>(0, (sum, s) => sum + s.quantity) +
              interSiteItems.where((i) => i.weight == weight && (i.status == CylinderStatus.leak || i.status == CylinderStatus.leakInTransit)).fold<int>(0, (sum, i) => sum + i.quantity),
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

  /// Calcule l'inventaire de conservation du parc bouteilles.
  ///
  /// Invariant : registeredTotal = Pleines + Vides + Problèmes (Fuites/Déf.) + Transit
  ///
  /// [cylinders]   : types de cylindres avec leur registeredTotal
  /// [allStocks]   : tous les CylinderStock (dépôt + POS) de l'entreprise et ses enfants
  /// [transfers]   : transferts inter-sites expédiés (shipped)
  static BottleConservationResult calculateConservation({
    required List<Cylinder> cylinders,
    required List<CylinderStock> allStocks,
    required List<StockTransfer> transfers,
  }) {
    final items = <BottleConservationItem>[];

    for (final cylinder in cylinders) {
      final w = cylinder.weight;
      final registered = cylinder.registeredTotal;

      final cId = cylinder.id;

      // Tous les items en transit inter-site pour ce poids
      // NOTE: Les transferts n'ont pas de cylinderId, on reste sur le poids
      final shippedItems = transfers
          .where((t) => t.status == StockTransferStatus.shipped)
          .expand((t) => t.items)
          .where((i) => i.weight == w);
      
      // PIVOT: Filtrer par cylinderId pour la précision absolue
      final relatedStocks = allStocks.where((s) => s.cylinderId == cId);

      // 1. Pleines (Magasin/POS + Transit inter-site)
      final totalFull = relatedStocks
          .where((s) => s.status == CylinderStatus.full)
          .fold<int>(0, (sum, s) => sum + s.quantity) +
          shippedItems.where((i) => i.status == CylinderStatus.full)
          .fold<int>(0, (sum, i) => sum + i.quantity);
          
      // 2. Vides (Magasin/POS + Tournées + Transit inter-site)
      final totalEmpty = relatedStocks
          .where((s) => s.status == CylinderStatus.emptyAtStore || s.status == CylinderStatus.emptyInTransit)
          .fold<int>(0, (sum, s) => sum + s.quantity) +
          shippedItems.where((i) => i.status == CylinderStatus.emptyAtStore || i.status == CylinderStatus.emptyInTransit)
          .fold<int>(0, (sum, i) => sum + i.quantity);

      // 3. Problèmes / Fuites (Magasin/POS + Tournées + Transit inter-site)
      final totalIssues = relatedStocks
          .where((s) => 
            s.status == CylinderStatus.leak || 
            s.status == CylinderStatus.leakInTransit || 
            s.status == CylinderStatus.defective
          )
          .fold<int>(0, (sum, s) => sum + s.quantity) +
          shippedItems.where((i) => 
            i.status == CylinderStatus.leak || 
            i.status == CylinderStatus.leakInTransit || 
            i.status == CylinderStatus.defective
          )
          .fold<int>(0, (sum, i) => sum + i.quantity);

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



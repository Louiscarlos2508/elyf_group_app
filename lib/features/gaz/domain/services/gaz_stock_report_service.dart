import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../entities/cylinder.dart';
import '../entities/stock_movement.dart';
import '../repositories/cylinder_stock_repository.dart';

class GazStockReportService {
  const GazStockReportService({
    required this.auditRepository,
    required this.stockRepository,
  });

  final AuditTrailRepository auditRepository;
  final CylinderStockRepository stockRepository;

  /// Récupère l'historique des mouvements de stock pour une période donnée.
  Future<List<StockMovement>> getStockHistory({
    required List<String> enterpriseIds,
    DateTime? startDate,
    DateTime? endDate,
    String? siteId,
  }) async {
    final records = await auditRepository.fetchRecordsForEnterprises(
      enterpriseIds: enterpriseIds,
      startDate: startDate,
      endDate: endDate,
      module: 'gaz',
    );

    final movements = <StockMovement>[];

    for (final record in records) {
      final metadata = record.metadata;
      if (metadata == null || !metadata.containsKey('movements')) continue;

      final operation = metadata['operation'] as String?;
      final type = _mapOperationToType(operation);

      final movementsData = metadata['movements'] as List<dynamic>;
      for (final moveData in movementsData) {
        final moveMap = moveData as Map<String, dynamic>;
        
        // Filtrer par site si nécessaire
        final moveSiteId = moveMap['siteId'] as String? ?? metadata['siteId'] as String?;
        if (siteId != null && moveSiteId != siteId) continue;

        movements.add(StockMovement(
          id: '${record.id}_${movements.length}',
          enterpriseId: record.enterpriseId,
          timestamp: record.timestamp,
          type: type,
          cylinderId: moveMap['cylinderId'] as String? ?? metadata['cylinderId'] as String? ?? 'N/A',
          weight: (moveMap['weight'] as num?)?.toInt() ?? (metadata['weight'] as num?)?.toInt() ?? 0,
          status: CylinderStatus.values.byName(moveMap['status'] as String),
          quantityDelta: (moveMap['delta'] as num).toInt(),
          siteId: moveSiteId,
          userId: record.userId,
          referenceId: record.entityId,
          notes: metadata['reason'] as String? ?? metadata['notes'] as String?,
        ));
      }
    }

    // Trier par date décroissante
    movements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return movements;
  }

  /// Calcule un résumé du stock actuel (global ou par site).
  Future<Map<int, Map<CylinderStatus, int>>> getStockSummary({
    required List<String> enterpriseIds,
    String? siteId,
  }) async {
    final stocks = await stockRepository.getAllForEnterprises(enterpriseIds);
    
    final summary = <int, Map<CylinderStatus, int>>{};

    for (final stock in stocks) {
      if (siteId != null && stock.siteId != siteId) continue;

      if (!summary.containsKey(stock.weight)) {
        summary[stock.weight] = {
          for (final status in CylinderStatus.values) status: 0
        };
      }

      final weightSummary = summary[stock.weight]!;
      weightSummary[stock.status] = (weightSummary[stock.status] ?? 0) + stock.quantity;
    }

    return summary;
  }

  StockMovementType _mapOperationToType(String? operation) {
    switch (operation) {
      case 'sale':
        return StockMovementType.sale;
      case 'replenishment':
        return StockMovementType.replenishment;
      case 'leak':
        return StockMovementType.leak;
      case 'defective':
        return StockMovementType.defective;
      case 'exchange':
        return StockMovementType.exchange;
      case 'adjustment':
        return StockMovementType.adjustment;
      default:
        return StockMovementType.adjustment;
    }
  }
}

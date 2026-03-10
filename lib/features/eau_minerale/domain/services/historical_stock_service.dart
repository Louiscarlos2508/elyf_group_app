import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import 'stock_history_service.dart';
import '../../application/controllers/stock_controller.dart';

/// Service dédié au calcul de l'état historique des stocks par "rembobinage".
///
/// Ce service extrait la logique complexe de calcul du stock à une date passée
/// hors du StockController.
class HistoricalStockService {
  HistoricalStockService(this._stockController, this._stockHistoryService);

  final StockController _stockController;
  final StockHistoryService _stockHistoryService;

  /// Calcule l'état des stocks à une date précise par "rembobinage" des mouvements.
  /// Stock(Date) = Stock(Maintenant) - ∑Entrées(Date->Maintenant) + ∑Sorties(Date->Maintenant)
  Future<StockState> fetchStockStateAtDate(DateTime targetDate) async {
    // 1. Obtenir l'état actuel
    final currentSnapshot = await _stockController.fetchSnapshot();
    
    // Normaliser targetDate à la fin de la journée (23:59:59)
    final endOfTargetDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23, 59, 59, 999,
    );
    
    // Si la date est aujourd'hui ou dans le futur, retourner le snapshot actuel
    if (endOfTargetDate.isAfter(DateTime.now())) {
      return currentSnapshot;
    }

    // 2. Récupérer TOUS les mouvements depuis la fin de targetDate jusqu'à maintenant
    final movements = await _stockHistoryService.fetchAllMovements(
      startDate: endOfTargetDate.add(const Duration(milliseconds: 1)),
    );

    // 3. Préparer les Listes de stock à modifier (copies)
    final items = List<StockItem>.from(currentSnapshot.items);

    // 4. Appliquer le "rembobinage" (Reverse movements)
    for (final m in movements) {
      final isEntry = m.type == StockMovementType.entry;
      final qty = m.quantity;
      final productId = m.productId;

      // a. Mettre à jour dans les items génériques (utilisés par StockScreen)
      final itemIndex = items.indexWhere((i) => i.id == productId);
      if (itemIndex != -1) {
        final i = items[itemIndex];
        final newQty = isEntry ? i.quantity - qty : i.quantity + qty;
        items[itemIndex] = i.copyWith(quantity: newQty >= 0 ? newQty : 0);
      }
    }

    AppLogger.debug(
      'Reconstructed stock state at $endOfTargetDate\n'
      'Base movements reversed: ${movements.length}',
      name: 'HistoricalStockService',
    );
    
    // Calculer le total des bobines
    final totalBobines = items.where((i) => i.type == StockType.rawMaterial).fold<int>(
      0,
      (sum, item) => sum + item.quantity.toInt(),
    );

    return StockState(
      items: items,
      availableMachineMaterials: totalBobines, // Les bobines calculées pour l'historique
    );
  }
}

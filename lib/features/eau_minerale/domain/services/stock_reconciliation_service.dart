import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_repository.dart';

/// Service dédié à la réconciliation des stocks basés sur l'historique des mouvements.
class StockReconciliationService {
  StockReconciliationService(
    this._stockRepository,
  );

  final StockRepository _stockRepository;

  /// Calcule la quantité théorique d'un produit en sommant tous ses mouvements.
  Future<double> computeQuantityFromMovements(String productId) async {
    final movements = await _stockRepository.fetchMovements(productId: productId);
    
    double qty = 0;
    for (final m in movements) {
      if (m.type == StockMovementType.entry) {
        qty += m.quantity;
      } else {
        qty -= m.quantity;
      }
    }
    return qty;
  }

  /// Aligne la quantité en stock avec la somme des mouvements.
  /// Note: Cette méthode devient moins cruciale si on calcule tout dynamiquement,
  /// mais elle peut servir à mettre à jour un cache ou une table de "Stock Actuel".
  Future<bool> reconcileProductQuantity(String productId) async {
    final expected = await computeQuantityFromMovements(productId);
    
    // Si on veut sauvegarder cette valeur quelque part :
    try {
      await _stockRepository.updateStock(productId, expected.toInt());
      return true;
    } catch (_) {
      return false;
    }
  }
}

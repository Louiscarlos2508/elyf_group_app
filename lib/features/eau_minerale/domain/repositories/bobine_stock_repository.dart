import '../entities/bobine_stock_movement.dart';

/// Repository pour gérer les mouvements de stock des bobines.
abstract class BobineStockRepository {
  /// Enregistre un mouvement de stock.
  Future<void> recordMovement(BobineStockMovement movement);

  /// Récupère les mouvements de stock.
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineId,
    String? productionId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère le nombre de bobines disponibles en stock.
  Future<int> countAvailableBobines();
}

import '../entities/bobine_stock.dart';
import '../entities/bobine_stock_movement.dart';

/// Repository pour gérer le stock de bobines par type et quantité (comme les emballages).
abstract class BobineStockQuantityRepository {
  /// Récupère tous les stocks de bobines.
  Future<List<BobineStock>> fetchAll();

  /// Récupère un stock de bobine par son ID.
  Future<BobineStock?> fetchById(String id);

  /// Récupère un stock de bobine par son type.
  Future<BobineStock?> fetchByType(String type);

  /// Crée ou met à jour un stock de bobine.
  Future<BobineStock> save(BobineStock stock);

  /// Enregistre un mouvement de stock.
  Future<void> recordMovement(BobineStockMovement movement);

  /// Récupère les mouvements de stock.
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineStockId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère les stocks avec alerte (stock faible).
  Future<List<BobineStock>> fetchLowStockAlerts();
}


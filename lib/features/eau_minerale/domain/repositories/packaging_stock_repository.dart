import '../entities/packaging_stock.dart';
import '../entities/packaging_stock_movement.dart';

/// Repository pour gérer le stock d'emballages.
abstract class PackagingStockRepository {
  /// Récupère tous les stocks d'emballages.
  Future<List<PackagingStock>> fetchAll();

  /// Récupère un stock d'emballage par son ID.
  Future<PackagingStock?> fetchById(String id);

  /// Récupère un stock d'emballage par son type.
  Future<PackagingStock?> fetchByType(String type);

  /// Crée ou met à jour un stock d'emballage.
  Future<PackagingStock> save(PackagingStock stock);

  /// Enregistre un mouvement de stock.
  Future<void> recordMovement(PackagingStockMovement movement);

  /// Récupère les mouvements de stock.
  Future<List<PackagingStockMovement>> fetchMovements({
    String? packagingId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère les stocks avec alerte (stock faible).
  Future<List<PackagingStock>> fetchLowStockAlerts();
}

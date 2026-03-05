import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/repositories/packaging_stock_repository.dart';

/// Controller pour gérer le stock d'emballages.
class PackagingStockController {
  PackagingStockController(this._repository);

  final PackagingStockRepository _repository;

  /// Récupère tous les stocks d'emballages.
  Future<List<PackagingStock>> fetchAll() async {
    return _repository.fetchAll();
  }

  /// Récupère un stock d'emballage par son ID.
  Future<PackagingStock?> fetchById(String id) async {
    return _repository.fetchById(id);
  }

  /// Récupère un stock d'emballage par son type.
  Future<PackagingStock?> fetchByType(String type) async {
    return _repository.fetchByType(type);
  }

  /// Crée ou met à jour un stock d'emballage.
  Future<PackagingStock> save(PackagingStock stock) async {
    return _repository.save(stock);
  }

  /// Enregistre un mouvement de stock d'emballage.
  Future<void> recordMovement(PackagingStockMovement movement) async {
    return _repository.recordMovement(movement);
  }

  /// Récupère les mouvements de stock d'emballages.
  Future<List<PackagingStockMovement>> fetchMovements({
    String? packagingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _repository.fetchMovements(
      packagingId: packagingId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Récupère les stocks avec alerte (stock faible).
  Future<List<PackagingStock>> fetchLowStockAlerts() async {
    return _repository.fetchLowStockAlerts();
  }
}

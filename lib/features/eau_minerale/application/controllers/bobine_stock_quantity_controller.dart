import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';

/// Controller pour gérer le stock de bobines par type et quantité.
class BobineStockQuantityController {
  BobineStockQuantityController(this._repository);

  final BobineStockQuantityRepository _repository;

  /// Récupère tous les stocks de bobines.
  Future<List<BobineStock>> fetchAll() async {
    return _repository.fetchAll();
  }

  /// Récupère un stock de bobine par son ID.
  Future<BobineStock?> fetchById(String id) async {
    return _repository.fetchById(id);
  }

  /// Récupère un stock de bobine par son type.
  Future<BobineStock?> fetchByType(String type) async {
    return _repository.fetchByType(type);
  }

  /// Crée ou met à jour un stock de bobine.
  Future<BobineStock> save(BobineStock stock) async {
    return _repository.save(stock);
  }

  /// Enregistre un mouvement de stock de bobine.
  Future<void> recordMovement(BobineStockMovement movement) async {
    return _repository.recordMovement(movement);
  }

  /// Récupère les mouvements de stock de bobines.
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineStockId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _repository.fetchMovements(
      bobineStockId: bobineStockId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Récupère les stocks avec alerte (stock faible).
  Future<List<BobineStock>> fetchLowStockAlerts() async {
    return _repository.fetchLowStockAlerts();
  }
}

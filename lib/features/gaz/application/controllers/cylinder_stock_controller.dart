import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';
import '../../domain/services/stock_service.dart';

/// Contrôleur pour la gestion des stocks de bouteilles.
class CylinderStockController {
  CylinderStockController(this._repository, this._stockService);

  final CylinderStockRepository _repository;
  final StockService _stockService;

  /// Récupère les stocks par statut.
  Future<List<CylinderStock>> getStocksByStatus(
    String enterpriseId,
    CylinderStatus status, {
    String? siteId,
  }) async {
    return _repository.getStocksByStatus(enterpriseId, status, siteId: siteId);
  }

  /// Observe les stocks en temps réel.
  Stream<List<CylinderStock>> watchStocks(
    String enterpriseId, {
    CylinderStatus? status,
    String? siteId,
  }) {
    return _repository.watchStocks(
      enterpriseId,
      status: status,
      siteId: siteId,
    );
  }

  /// Récupère les stocks par poids.
  Future<List<CylinderStock>> getStocksByWeight(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    return _repository.getStocksByWeight(enterpriseId, weight, siteId: siteId);
  }

  /// Récupère un stock par ID.
  Future<CylinderStock?> getStockById(String id) async {
    return _repository.getStockById(id);
  }

  /// Change le statut d'un stock.
  Future<void> changeStockStatus(
    String stockId,
    CylinderStatus newStatus,
  ) async {
    await _stockService.changeStockStatus(stockId, newStatus);
  }

  /// Ajuste la quantité d'un stock.
  Future<void> adjustStockQuantity(String stockId, int newQuantity) async {
    await _stockService.adjustStockQuantity(stockId, newQuantity);
  }

  /// Récupère le stock disponible (pleines) pour un format.
  Future<int> getAvailableStock(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    return _stockService.getAvailableStock(
      enterpriseId,
      weight,
      siteId: siteId,
    );
  }

  /// Récupère les stocks par site.
  Future<List<CylinderStock>> getStockBySite(
    String enterpriseId,
    String siteId,
  ) async {
    return _repository.getStockBySite(enterpriseId, siteId);
  }

  /// Ajoute un nouveau stock.
  Future<void> addStock(CylinderStock stock) async {
    await _repository.addStock(stock);
  }

  /// Met à jour un stock.
  Future<void> updateStock(CylinderStock stock) async {
    await _repository.updateStock(stock);
  }
}

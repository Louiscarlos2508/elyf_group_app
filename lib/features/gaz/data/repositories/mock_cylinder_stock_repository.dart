import '../../domain/entities/cylinder_stock.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';

/// Implémentation mock du repository de stocks de bouteilles.
class MockCylinderStockRepository implements CylinderStockRepository {
  final List<CylinderStock> _stocks = [];

  @override
  Future<List<CylinderStock>> getStocksByStatus(
    String enterpriseId,
    CylinderStatus status, {
    String? siteId,
  }) async {
    return _stocks.where((s) {
      if (s.enterpriseId != enterpriseId) return false;
      if (s.status != status) return false;
      if (siteId != null && s.siteId != siteId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<CylinderStock>> getStocksByWeight(
    String enterpriseId,
    int weight, {
    String? siteId,
  }) async {
    return _stocks.where((s) {
      if (s.enterpriseId != enterpriseId) return false;
      if (s.weight != weight) return false;
      if (siteId != null && s.siteId != siteId) return false;
      return true;
    }).toList();
  }

  @override
  Future<CylinderStock?> getStockById(String id) async {
    return _stocks.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<void> updateStockQuantity(String id, int newQuantity) async {
    final index = _stocks.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stocks[index] = _stocks[index].copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> changeStockStatus(
    String id,
    CylinderStatus newStatus,
  ) async {
    final index = _stocks.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stocks[index] = _stocks[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<CylinderStock>> getStockBySite(
    String enterpriseId,
    String siteId,
  ) async {
    return _stocks.where((s) {
      return s.enterpriseId == enterpriseId && s.siteId == siteId;
    }).toList();
  }

  @override
  Future<void> addStock(CylinderStock stock) async {
    _stocks.add(stock);
  }

  @override
  Future<void> updateStock(CylinderStock stock) async {
    final index = _stocks.indexWhere((s) => s.id == stock.id);
    if (index != -1) {
      _stocks[index] = stock.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deleteStock(String id) async {
    _stocks.removeWhere((s) => s.id == id);
  }
}
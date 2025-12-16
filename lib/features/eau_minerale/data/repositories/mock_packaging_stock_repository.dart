import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/repositories/packaging_stock_repository.dart';

class MockPackagingStockRepository implements PackagingStockRepository {
  final List<PackagingStock> _stocks = [
    PackagingStock(
      id: 'packaging-1',
      type: 'Emballage',
      quantity: 100,
      unit: 'unité',
      seuilAlerte: 20,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
  ];
  final List<PackagingStockMovement> _movements = [];

  @override
  Future<List<PackagingStock>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_stocks);
  }

  @override
  Future<PackagingStock?> fetchById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _stocks.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<PackagingStock?> fetchByType(String type) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _stocks.firstWhere((s) => s.type == type);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<PackagingStock> save(PackagingStock stock) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _stocks.indexWhere((s) => s.id == stock.id);
    if (index == -1) {
      _stocks.add(stock);
    } else {
      _stocks[index] = stock;
    }
    return stock;
  }

  @override
  Future<void> recordMovement(PackagingStockMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _movements.add(movement);
  }

  @override
  Future<List<PackagingStockMovement>> fetchMovements({
    String? packagingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var filtered = _movements;

    if (packagingId != null) {
      filtered = filtered.where((m) => m.packagingId == packagingId).toList();
    }

    if (startDate != null) {
      filtered = filtered.where((m) => m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate)).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((m) => m.date.isBefore(endDate) || m.date.isAtSameMomentAs(endDate)).toList();
    }

    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<PackagingStock>> fetchLowStockAlerts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _stocks.where((s) => s.estStockFaible).toList();
  }
}

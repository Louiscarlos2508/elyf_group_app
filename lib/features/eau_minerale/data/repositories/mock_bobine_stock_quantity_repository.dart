import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';

class MockBobineStockQuantityRepository
    implements BobineStockQuantityRepository {
  final List<BobineStock> _stocks = [
    BobineStock(
      id: 'bobine-stock-1',
      type: 'Bobine standard',
      quantity: 50,
      unit: 'unité',
      seuilAlerte: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
  ];
  final List<BobineStockMovement> _movements = [];

  @override
  Future<List<BobineStock>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_stocks);
  }

  @override
  Future<BobineStock?> fetchById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _stocks.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<BobineStock?> fetchByType(String type) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _stocks.firstWhere((s) => s.type == type);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<BobineStock> save(BobineStock stock) async {
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
  Future<void> recordMovement(BobineStockMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _movements.add(movement);
  }

  @override
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineStockId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var filtered = _movements;

    if (bobineStockId != null) {
      // Filtrer par bobineStockId si nécessaire
      // Pour l'instant, on utilise bobineId dans le mouvement
    }

    if (startDate != null) {
      filtered = filtered
          .where(
            (m) =>
                m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate),
          )
          .toList();
    }

    if (endDate != null) {
      filtered = filtered
          .where(
            (m) => m.date.isBefore(endDate) || m.date.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<BobineStock>> fetchLowStockAlerts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _stocks.where((s) => s.estStockFaible).toList();
  }
}

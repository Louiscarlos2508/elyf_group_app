import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/repositories/bobine_stock_repository.dart';

class MockBobineStockRepository implements BobineStockRepository {
  final List<BobineStockMovement> _movements = [];

  @override
  Future<void> recordMovement(BobineStockMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _movements.add(movement);
  }

  @override
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineId,
    String? productionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var filtered = _movements;

    if (bobineId != null) {
      filtered = filtered.where((m) => m.bobineId == bobineId).toList();
    }

    if (productionId != null) {
      filtered = filtered.where((m) => m.productionId == productionId).toList();
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
  Future<int> countAvailableBobines() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Compter les entrées moins les sorties
    final entrees = _movements.where((m) => m.type == BobineMovementType.entree).length;
    final sorties = _movements.where((m) => m.type == BobineMovementType.sortie).length;
    return (entrees - sorties).clamp(0, double.infinity).toInt();
  }
}

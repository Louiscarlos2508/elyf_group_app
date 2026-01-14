import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/repositories/liquidity_repository.dart';

/// Mock implementation of LiquidityRepository for development.
class MockLiquidityRepository implements LiquidityRepository {
  final _checkpoints = <String, LiquidityCheckpoint>{};

  MockLiquidityRepository() {
    // Initialize with sample data
    final today = DateTime.now();
    _checkpoints['checkpoint-1'] = LiquidityCheckpoint(
      id: 'checkpoint-1',
      enterpriseId: 'orange_money_1',
      date: today,
      type: LiquidityCheckpointType.full,
      amount: 5000000,
      morningCheckpoint: 5000000,
      eveningCheckpoint: 4500000,
      notes: 'Pointage complet du jour',
      createdAt: today.subtract(const Duration(hours: 2)),
      updatedAt: today.subtract(const Duration(hours: 1)),
    );
  }

  @override
  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var checkpoints = _checkpoints.values.toList();

    if (enterpriseId != null) {
      checkpoints = checkpoints
          .where((c) => c.enterpriseId == enterpriseId)
          .toList();
    }

    if (startDate != null) {
      final normalizedStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      checkpoints = checkpoints
          .where((c) => !c.date.isBefore(normalizedStart))
          .toList();
    }

    if (endDate != null) {
      final normalizedEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      checkpoints = checkpoints
          .where((c) => !c.date.isAfter(normalizedEnd))
          .toList();
    }

    checkpoints.sort((a, b) => b.date.compareTo(a.date));
    return checkpoints;
  }

  @override
  Future<LiquidityCheckpoint?> getCheckpoint(String checkpointId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _checkpoints[checkpointId];
  }

  @override
  Future<LiquidityCheckpoint?> getTodayCheckpoint(String enterpriseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return _checkpoints.values.firstWhere(
      (c) =>
          c.enterpriseId == enterpriseId &&
          c.date.year == normalizedToday.year &&
          c.date.month == normalizedToday.month &&
          c.date.day == normalizedToday.day,
      orElse: () => LiquidityCheckpoint(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        date: normalizedToday,
        type: LiquidityCheckpointType.morning,
        amount: 0,
      ),
    );
  }

  @override
  Future<String> createCheckpoint(LiquidityCheckpoint checkpoint) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _checkpoints[checkpoint.id] = checkpoint;
    return checkpoint.id;
  }

  @override
  Future<void> updateCheckpoint(LiquidityCheckpoint checkpoint) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _checkpoints[checkpoint.id] = checkpoint;
  }

  @override
  Future<void> deleteCheckpoint(String checkpointId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _checkpoints.remove(checkpointId);
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final checkpoints = await fetchCheckpoints(
      enterpriseId: enterpriseId,
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'totalCheckpoints': checkpoints.length,
      'completeCheckpoints': checkpoints.where((c) => c.isComplete).length,
      'incompleteCheckpoints': checkpoints.where((c) => !c.isComplete).length,
    };
  }
}

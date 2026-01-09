import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/data/repositories/stock_offline_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';

void main() {
  group('StockOfflineRepository', () {
    late StockOfflineRepository repository;

    setUp(() {
      repository = StockOfflineRepository(
        driftService: DriftService.instance,
        syncManager: SyncManager(driftService: DriftService.instance),
        connectivityService: ConnectivityService(),
        enterpriseId: 'test_enterprise',
      );
    });

    test('should create stock movement', () async {
      final movement = StockMovement(
        id: '',
        date: DateTime.now(),
        productName: 'Test Product',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 100.0,
        unit: 'unit',
      );

      await repository.recordMovement(movement);
      final movements = await repository.fetchMovements();
      
      expect(movements.length, greaterThan(0));
    });

    test('should filter movements by date range', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final movement1 = StockMovement(
        id: '',
        date: yesterday,
        productName: 'Product A',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 50.0,
        unit: 'unit',
      );

      final movement2 = StockMovement(
        id: '',
        date: tomorrow,
        productName: 'Product B',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 30.0,
        unit: 'unit',
      );

      await repository.recordMovement(movement1);
      await repository.recordMovement(movement2);

      final movements = await repository.fetchMovements(
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now,
      );

      expect(movements.length, greaterThanOrEqualTo(1));
    });
  });
}


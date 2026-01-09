import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/data/repositories/stock_offline_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';

void main() {
  group('OfflineRepository Tests', () {
    late DriftService driftService;
    late SyncManager syncManager;
    late ConnectivityService connectivityService;
    late StockOfflineRepository repository;

    setUp(() async {
      // Initialize services
      driftService = DriftService.instance;
      syncManager = SyncManager(driftService: driftService);
      connectivityService = ConnectivityService();
      
      repository = StockOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: 'test_enterprise',
      );
    });

    test('should create and save stock movement locally', () async {
      final movement = StockMovement(
        id: '',
        date: DateTime.now(),
        productName: 'Test Product',
        type: StockMovementType.entry,
        reason: 'Test reason',
        quantity: 100.0,
        unit: 'unit',
      );

      await repository.recordMovement(movement);

      final movements = await repository.fetchMovements();
      expect(movements.length, greaterThan(0));
      expect(movements.any((m) => m.productName == 'Test Product'), isTrue);
    });

    test('should filter movements by product', () async {
      final movement1 = StockMovement(
        id: '',
        date: DateTime.now(),
        productName: 'Product A',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 50.0,
        unit: 'unit',
      );

      final movement2 = StockMovement(
        id: '',
        date: DateTime.now(),
        productName: 'Product B',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 30.0,
        unit: 'unit',
      );

      await repository.recordMovement(movement1);
      await repository.recordMovement(movement2);

      final movements = await repository.fetchMovements(productId: 'Product A');
      expect(movements.every((m) => m.productName == 'Product A'), isTrue);
    });

    test('should calculate stock correctly', () async {
      final entry = StockMovement(
        id: '',
        date: DateTime.now(),
        productName: 'Test Product',
        type: StockMovementType.entry,
        reason: 'Entry',
        quantity: 100.0,
        unit: 'unit',
      );

      final exit = StockMovement(
        id: '',
        date: DateTime.now(),
        productName: 'Test Product',
        type: StockMovementType.exit,
        reason: 'Exit',
        quantity: 30.0,
        unit: 'unit',
      );

      await repository.recordMovement(entry);
      await repository.recordMovement(exit);

      final stock = await repository.getStock('Test Product');
      expect(stock, equals(70));
    });
  });
}


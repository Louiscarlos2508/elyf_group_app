import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/handlers/firebase_sync_handler.dart';
import 'package:elyf_groupe_app/features/eau_minerale/data/repositories/stock_offline_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/data/repositories/mock_product_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';

/// Mock connectivity service for testing.
class MockConnectivityService implements ConnectivityService {
  MockConnectivityService({required this.isOnline});

  @override
  final bool isOnline;

  @override
  ConnectivityStatus get currentStatus =>
      isOnline ? ConnectivityStatus.wifi : ConnectivityStatus.offline;

  @override
  Stream<ConnectivityStatus> get statusStream =>
      Stream.value(currentStatus);

  @override
  Future<void> initialize() async {
    // No-op for testing
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async => currentStatus;

  @override
  Future<void> dispose() async {
    // No-op for testing
  }
}

void main() {
  group('StockOfflineRepository', () {
    late StockOfflineRepository repository;

    setUp(() async {
      final driftService = DriftService.instance;
      await driftService.initialize();
      final connectivityService = MockConnectivityService(isOnline: true);
      await connectivityService.initialize();
      final syncManager = SyncManager(
        driftService: driftService,
        connectivityService: connectivityService,
        config: const SyncConfig(
          maxRetryAttempts: 3,
          syncIntervalMinutes: 5,
          maxOperationAgeHours: 72,
        ),
        syncHandler: MockSyncHandler(),
      );
      await syncManager.initialize();
      
      repository = StockOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: 'test_enterprise',
        moduleType: 'eau_minerale',
        productRepository: MockProductRepository(),
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


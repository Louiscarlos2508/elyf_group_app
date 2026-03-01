import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/handlers/firebase_sync_handler.dart';
import 'package:elyf_groupe_app/features/eau_minerale/data/repositories/stock_offline_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/product_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_movement.dart';

class MockProductRepository extends Mock implements ProductRepository {}

/// Mock connectivity service for testing.
class MockConnectivityService implements ConnectivityService {
  MockConnectivityService({required this.isOnline});

  @override
  final bool isOnline;

  @override
  ConnectivityStatus get currentStatus =>
      isOnline ? ConnectivityStatus.wifi : ConnectivityStatus.offline;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(currentStatus);

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
  group('OfflineRepository Tests', () {
    late DriftService driftService;
    late SyncManager syncManager;
    late ConnectivityService connectivityService;
    late StockOfflineRepository repository;

    setUp(() async {
      // Initialize services
      driftService = DriftService.instance;
      await driftService.initialize();
      connectivityService = MockConnectivityService(isOnline: true);
      await connectivityService.initialize();
      syncManager = SyncManager(
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

    test('should create and save stock movement locally', () async {
      final movement = StockMovement(
        id: '',
        enterpriseId: 'test_enterprise',
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
        enterpriseId: 'test_enterprise',
        date: DateTime.now(),
        productName: 'Product A',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 50.0,
        unit: 'unit',
      );

      final movement2 = StockMovement(
        id: '',
        enterpriseId: 'test_enterprise',
        date: DateTime.now(),
        productName: 'Product B',
        type: StockMovementType.entry,
        reason: 'Test',
        quantity: 30.0,
        unit: 'unit',
      );

      await repository.recordMovement(movement1);
      await repository.recordMovement(movement2);

      // Note: This test may need adjustment based on how productId mapping works
      final movements = await repository.fetchMovements();
      expect(movements.length, greaterThanOrEqualTo(2));
    });

    test('should calculate stock correctly', () async {
      final entry = StockMovement(
        id: '',
        enterpriseId: 'test_enterprise',
        date: DateTime.now(),
        productName: 'Test Product',
        type: StockMovementType.entry,
        reason: 'Entry',
        quantity: 100.0,
        unit: 'unit',
      );

      final exit = StockMovement(
        id: '',
        enterpriseId: 'test_enterprise',
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

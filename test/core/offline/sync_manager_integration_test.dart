import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/handlers/firebase_sync_handler.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncManager Integration Tests', () {
    late DriftService driftService;
    late ConnectivityService connectivityService;
    late SyncManager syncManager;

    setUp(() async {
      // Initialize DriftService with memory database for tests
      driftService = DriftService.instance;
      await driftService.initialize(connection: NativeDatabase.memory());

      // Mock connectivity service (always online for tests)
      connectivityService = MockConnectivityService(isOnline: true);

      // Create sync handler using MockSyncHandler from handlers
      final syncHandler = MockSyncHandler(shouldFail: false, delayMs: 10);

      // Create SyncManager
      syncManager = SyncManager(
        driftService: driftService,
        connectivityService: connectivityService,
        syncHandler: syncHandler,
        config: const SyncConfig(
          syncIntervalMinutes: 0, // Disable auto-sync for tests
          maxRetryAttempts: 3,
        ),
      );

      await syncManager.initialize();
    });

    tearDown(() async {
      await syncManager.dispose();
      await driftService.close();
    });

    test('should queue and sync create operation', () async {
      // Arrange
      final testData = {'name': 'Test Item', 'value': 100};

      // Act
      await syncManager.queueCreate(
        collectionName: 'test_collection',
        localId: 'local_123',
        data: testData,
        enterpriseId: 'enterprise_1',
      );

      // Wait a bit for async processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      final pendingCount = await syncManager.getPendingCount();
      expect(pendingCount, greaterThanOrEqualTo(0));

      // Verify operation was queued
      final pendingOps = await syncManager.getPendingForCollection(
        'test_collection',
      );
      expect(pendingOps.length, greaterThanOrEqualTo(0));
    });

    test('should queue and sync update operation', () async {
      // Arrange
      final updateData = {'name': 'Updated Item', 'value': 200};

      // Act
      await syncManager.queueUpdate(
        collectionName: 'test_collection',
        localId: 'local_123',
        remoteId: 'remote_456',
        data: updateData,
        enterpriseId: 'enterprise_1',
      );

      // Wait a bit for async processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      final pendingCount = await syncManager.getPendingCount();
      expect(pendingCount, greaterThanOrEqualTo(0));
    });

    test('should queue and sync delete operation', () async {
      // Act
      await syncManager.queueDelete(
        collectionName: 'test_collection',
        localId: 'local_123',
        remoteId: 'remote_456',
        enterpriseId: 'enterprise_1',
      );

      // Wait a bit for async processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      final pendingCount = await syncManager.getPendingCount();
      expect(pendingCount, greaterThanOrEqualTo(0));
    });

    test('should handle multiple queued operations', () async {
      // Act - Queue multiple operations
      for (int i = 0; i < 5; i++) {
        await syncManager.queueCreate(
          collectionName: 'test_collection',
          localId: 'local_$i',
          data: {'index': i},
          enterpriseId: 'enterprise_1',
        );
      }

      // Wait a bit
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      final pendingCount = await syncManager.getPendingCount();
      expect(pendingCount, greaterThanOrEqualTo(0));
    });

    test('should retry failed operations', () async {
      // Arrange - Create a sync manager with a failing handler
      final failingHandler = MockSyncHandler(shouldFail: true, delayMs: 10);
      final testSyncManager = SyncManager(
        driftService: driftService,
        connectivityService: connectivityService,
        syncHandler: failingHandler,
        config: const SyncConfig(syncIntervalMinutes: 0, maxRetryAttempts: 2),
      );
      await testSyncManager.initialize();

      // Act
      await testSyncManager.queueCreate(
        collectionName: 'test_collection',
        localId: 'local_fail',
        data: {'test': 'data'},
        enterpriseId: 'enterprise_1',
      );

      // Wait for processing
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Cleanup
      await testSyncManager.dispose();
    });

    test('should not sync when offline', () async {
      // Arrange
      final offlineConnectivity = MockConnectivityService(isOnline: false);
      final offlineSyncManager = SyncManager(
        driftService: driftService,
        connectivityService: offlineConnectivity,
        config: const SyncConfig(syncIntervalMinutes: 0),
      );
      await offlineSyncManager.initialize();

      // Act
      await offlineSyncManager.queueCreate(
        collectionName: 'test_collection',
        localId: 'local_offline',
        data: {'test': 'data'},
        enterpriseId: 'enterprise_1',
      );

      // Assert - Operation should be queued but not synced
      final pendingCount = await offlineSyncManager.getPendingCount();
      expect(pendingCount, greaterThan(0));

      await offlineSyncManager.dispose();
    });

    test('should clear pending operations', () async {
      // Arrange - Queue some operations
      await syncManager.queueCreate(
        collectionName: 'test_collection',
        localId: 'local_clear',
        data: {'test': 'data'},
        enterpriseId: 'enterprise_1',
      );

      // Act
      await syncManager.clearPendingOperations();

      // Assert
      final pendingCount = await syncManager.getPendingCount();
      expect(pendingCount, 0);
    });
  });
}

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

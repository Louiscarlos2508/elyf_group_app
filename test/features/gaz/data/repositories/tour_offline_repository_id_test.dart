import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/features/gaz/data/repositories/tour_offline_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';

// We don't need to generate mocks if we just want to test getLocalId which only uses the Tour entity
class MockDriftService extends Mock implements DriftService {}
class MockSyncManager extends Mock implements SyncManager {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('TourOfflineRepository ID Stability', () {
    late TourOfflineRepository repository;

    setUp(() {
      repository = TourOfflineRepository(
        driftService: MockDriftService(),
        syncManager: MockSyncManager(),
        connectivityService: MockConnectivityService(),
        enterpriseId: 'test_ent',
        moduleType: 'gaz',
      );
    });

    test('getLocalId should persist local_ prefix if already present', () {
      final tour = Tour(
        id: 'local_123',
        enterpriseId: 'test_ent',
        tourDate: DateTime.now(),
        status: TourStatus.open,
        loadingFeePerBottle: 0,
        unloadingFeePerBottle: 0,
      );

      expect(repository.getLocalId(tour), equals('local_123'));
    });

    test('getLocalId should persist remote ID if already present', () {
      final tour = Tour(
        id: 'remote_abc_789', // Simulating a remote ID
        enterpriseId: 'test_ent',
        tourDate: DateTime.now(),
        status: TourStatus.open,
        loadingFeePerBottle: 0,
        unloadingFeePerBottle: 0,
      );

      expect(repository.getLocalId(tour), equals('remote_abc_789'));
    });

    test('getLocalId should generate new local_ ID if empty', () {
      final tour = Tour(
        id: '',
        enterpriseId: 'test_ent',
        tourDate: DateTime.now(),
        status: TourStatus.open,
        loadingFeePerBottle: 0,
        unloadingFeePerBottle: 0,
      );

      final localId = repository.getLocalId(tour);
      expect(localId, startsWith('local_'));
    });
  });
}

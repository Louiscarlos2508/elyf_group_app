import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/handlers/firebase_sync_handler.dart';
import 'package:elyf_groupe_app/features/orange_money/data/repositories/commission_offline_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/commission.dart';
import 'package:mockito/mockito.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/repositories/audit_trail_repository.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/entities/audit_record.dart';
import 'package:elyf_groupe_app/core/offline/sync_operation_processor.dart';

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

class MockAuditTrailRepository extends Mock implements AuditTrailRepository {
  @override
  Future<String> log(AuditRecord record) async => '';
}

void main() {
  group('CommissionOfflineRepository', () {
    late CommissionOfflineRepository repository;

    setUp(() async {
      final driftService = DriftService.instance;
      await driftService.initialize(connection: NativeDatabase.memory());
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

      repository = CommissionOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: 'test_enterprise',
        moduleType: 'orange_money',
        auditTrailRepository: MockAuditTrailRepository(),
        userId: 'test_user',
      );
    });

    test('should create commission', () async {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final commission = Commission(
        id: '',
        period: period,
        estimatedAmount: 50000,
        status: CommissionStatus.estimated,
        transactionsCount: 100,
        enterpriseId: 'test_enterprise',
      );

      final id = await repository.createCommission(commission);
      expect(id, isNotEmpty);

      final created = await repository.getCommission(id);
      expect(created, isNotNull);
      expect(created?.period, equals(period));
      expect(created?.estimatedAmount, equals(50000));
    });

    test('should filter commissions by status', () async {
      final now = DateTime.now();
      final period1 = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final period2 =
          '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}';

      final commission1 = Commission(
        id: '',
        period: period1,
        estimatedAmount: 50000,
        status: CommissionStatus.estimated,
        transactionsCount: 100,
        enterpriseId: 'test_enterprise',
      );

      final commission2 = Commission(
        id: '',
        period: period2,
        estimatedAmount: 30000,
        status: CommissionStatus.paid,
        transactionsCount: 60,
        enterpriseId: 'test_enterprise',
      );

      await repository.createCommission(commission1);
      await repository.createCommission(commission2);

      final pending = await repository.fetchCommissions(
        enterpriseId: 'test_enterprise',
        status: CommissionStatus.estimated,
      );

      expect(
        pending.every((c) => c.status == CommissionStatus.estimated),
        isTrue,
      );
    });

    test('should get statistics', () async {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final commission1 = Commission(
        id: '',
        period: period,
        estimatedAmount: 50000,
        status: CommissionStatus.estimated,
        transactionsCount: 100,
        enterpriseId: 'test_enterprise',
      );

      final commission2 = Commission(
        id: '',
        period: '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}',
        estimatedAmount: 30000,
        status: CommissionStatus.paid,
        transactionsCount: 60,
        enterpriseId: 'test_enterprise',
      );

      await repository.createCommission(commission1);
      await repository.createCommission(commission2);

      final stats = await repository.getStatistics(
        enterpriseId: 'test_enterprise',
      );

      expect(stats['totalCommissions'], greaterThan(0));
      expect(stats['pendingCount'], greaterThan(0));
      expect(stats['paidCount'], greaterThan(0));
    });
  });
}

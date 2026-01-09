import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/features/orange_money/data/repositories/commission_offline_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/commission.dart';

void main() {
  group('CommissionOfflineRepository', () {
    late CommissionOfflineRepository repository;

    setUp(() {
      repository = CommissionOfflineRepository(
        driftService: DriftService.instance,
        syncManager: SyncManager(driftService: DriftService.instance),
        connectivityService: ConnectivityService(),
        enterpriseId: 'test_enterprise',
      );
    });

    test('should create commission', () async {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final commission = Commission(
        id: '',
        period: period,
        amount: 50000,
        status: CommissionStatus.pending,
        transactionsCount: 100,
        estimatedAmount: 50000,
        enterpriseId: 'test_enterprise',
      );

      final id = await repository.createCommission(commission);
      expect(id, isNotEmpty);

      final created = await repository.getCommission(id);
      expect(created, isNotNull);
      expect(created?.period, equals(period));
      expect(created?.amount, equals(50000));
    });

    test('should filter commissions by status', () async {
      final now = DateTime.now();
      final period1 = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final period2 = '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}';

      final commission1 = Commission(
        id: '',
        period: period1,
        amount: 50000,
        status: CommissionStatus.pending,
        transactionsCount: 100,
        estimatedAmount: 50000,
        enterpriseId: 'test_enterprise',
      );

      final commission2 = Commission(
        id: '',
        period: period2,
        amount: 30000,
        status: CommissionStatus.paid,
        transactionsCount: 60,
        estimatedAmount: 30000,
        enterpriseId: 'test_enterprise',
      );

      await repository.createCommission(commission1);
      await repository.createCommission(commission2);

      final pending = await repository.fetchCommissions(
        enterpriseId: 'test_enterprise',
        status: CommissionStatus.pending,
      );

      expect(pending.every((c) => c.status == CommissionStatus.pending), isTrue);
    });

    test('should get statistics', () async {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final commission1 = Commission(
        id: '',
        period: period,
        amount: 50000,
        status: CommissionStatus.pending,
        transactionsCount: 100,
        estimatedAmount: 50000,
        enterpriseId: 'test_enterprise',
      );

      final commission2 = Commission(
        id: '',
        period: '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}',
        amount: 30000,
        status: CommissionStatus.paid,
        transactionsCount: 60,
        estimatedAmount: 30000,
        enterpriseId: 'test_enterprise',
      );

      await repository.createCommission(commission1);
      await repository.createCommission(commission2);

      final stats = await repository.getStatistics(
        enterpriseId: 'test_enterprise',
      );

      expect(stats['totalCommissions'], greaterThan(0));
      expect(stats['pendingCommissions'], greaterThan(0));
      expect(stats['paidCommissions'], greaterThan(0));
    });
  });
}


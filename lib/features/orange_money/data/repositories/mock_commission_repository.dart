import 'dart:async';

import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';

/// Mock implementation of CommissionRepository for development.
class MockCommissionRepository implements CommissionRepository {
  final _commissions = <String, Commission>{};

  @override
  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var commissions = _commissions.values.toList();

    if (enterpriseId != null) {
      commissions = commissions
          .where((c) => c.enterpriseId == enterpriseId)
          .toList();
    }

    if (status != null) {
      commissions = commissions.where((c) => c.status == status).toList();
    }

    if (period != null) {
      commissions = commissions.where((c) => c.period == period).toList();
    }

    commissions.sort((a, b) => b.period.compareTo(a.period));
    return commissions;
  }

  @override
  Future<Commission?> getCommission(String commissionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _commissions[commissionId];
  }

  @override
  Future<Commission?> getCurrentMonthCommission(String enterpriseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final commissions = await fetchCommissions(
      enterpriseId: enterpriseId,
      period: period,
    );
    return commissions.isNotEmpty ? commissions.first : null;
  }

  @override
  Future<String> createCommission(Commission commission) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _commissions[commission.id] = commission;
    return commission.id;
  }

  @override
  Future<void> updateCommission(Commission commission) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _commissions[commission.id] = commission;
  }

  @override
  Future<Map<String, dynamic>> getStatistics({String? enterpriseId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final commissions = await fetchCommissions(enterpriseId: enterpriseId);

    final pendingCount = commissions.where((c) => c.isPending).length;
    final paidCount = commissions.where((c) => c.isPaid).length;
    final pendingAmount = commissions
        .where((c) => c.isPending)
        .fold<int>(0, (sum, c) => sum + c.amount);
    final paidAmount = commissions
        .where((c) => c.isPaid)
        .fold<int>(0, (sum, c) => sum + c.amount);

    // Estimé du mois en cours
    final currentMonth = await getCurrentMonthCommission(enterpriseId ?? '');
    final estimatedAmount = currentMonth?.estimatedAmount ?? 0;

    return {
      'periodsCount': commissions.length,
      'pendingCount': pendingCount,
      'paidCount': paidCount,
      'pendingAmount': pendingAmount,
      'paidAmount': paidAmount,
      'estimatedAmount': estimatedAmount,
    };
  }
}

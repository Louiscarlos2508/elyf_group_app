import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';

/// Controller for managing commissions.
import '../../domain/adapters/orange_money_permission_adapter.dart';

/// Controller for managing commissions.
class CommissionsController {
  CommissionsController(
    this._repository,
    this.userId,
    this._permissionAdapter,
    this._activeEnterpriseId,
  );

  final CommissionRepository _repository;
  final String userId;
  final OrangeMoneyPermissionAdapter _permissionAdapter;
  final String _activeEnterpriseId;

  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period,
  }) async {
    // If specific enterprise requested, use it
    if (enterpriseId != null) {
      return await _repository.fetchCommissions(
        enterpriseId: enterpriseId,
        status: status,
        period: period,
      );
    }

    // Otherwise, check hierarchy
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);

    if (accessibleIds.length > 1) {
      return await _repository.fetchCommissionsByEnterprises(
        accessibleIds.toList(),
        status: status,
        period: period,
      );
    }

    // Default to active enterprise
    return await _repository.fetchCommissions(
      enterpriseId: _activeEnterpriseId,
      status: status,
      period: period,
    );
  }

  Future<Commission?> getCommission(String commissionId) async {
    return await _repository.getCommission(commissionId);
  }

  Future<Commission?> getCurrentMonthCommission(String enterpriseId) async {
    return await _repository.getCurrentMonthCommission(enterpriseId);
  }

  Future<String> createCommission(Commission commission) async {
    return await _repository.createCommission(commission);
  }

  Future<void> updateCommission(Commission commission) async {
    return await _repository.updateCommission(commission);
  }

  Future<void> deleteCommission(String commissionId) async {
    return await _repository.deleteCommission(commissionId, userId);
  }

  Future<void> restoreCommission(String commissionId) async {
    return await _repository.restoreCommission(commissionId);
  }

  Stream<List<Commission>> watchDeletedCommissions() {
    return _repository.watchDeletedCommissions();
  }

  Future<Map<String, dynamic>> getStatistics({String? enterpriseId}) async {
    // If specific enterprise requested, use it
    if (enterpriseId != null) {
      return await _repository.getStatistics(enterpriseId: enterpriseId);
    }

    // Otherwise, check hierarchy (Note: getStatistics in repo might need update or we aggregate manually)
    // For now, if hierarchy, we might need to fetch all commissions and calculate.
    // But repository.getStatistics only takes single enterpriseId.
    // Let's implement an aggregate method if network view.
    
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    
    if (accessibleIds.length > 1) {
        final commissions = await _repository.fetchCommissionsByEnterprises(accessibleIds.toList());
        
        final paidCommissions = commissions.where((c) => c.status == CommissionStatus.paid).toList();
        final pendingCommissions = commissions.where((c) => c.status == CommissionStatus.validated).toList();
        final declaredCommissions = commissions.where((c) => c.status == CommissionStatus.declared).toList();

        return {
          'totalCommissions': commissions.length,
          'totalPaid': paidCommissions.fold<int>(0, (sum, c) => sum + c.finalAmount),
          'totalPending': pendingCommissions.fold<int>(0, (sum, c) => sum + c.finalAmount),
          'totalDeclared': declaredCommissions.fold<int>(0, (sum, c) => sum + c.finalAmount),
          'paidCount': paidCommissions.length,
          'pendingCount': pendingCommissions.length,
          'declaredCount': declaredCommissions.length,
          'isNetworkView': true,
        };
    }

    return await _repository.getStatistics(enterpriseId: _activeEnterpriseId);
  }
}

import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';
import '../../domain/adapters/orange_money_permission_adapter.dart';
import '../../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/utils/id_generator.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

/// Controller for managing commissions.
class CommissionsController {
  CommissionsController(
    this._repository,
    this._treasuryRepository,
    this.userId,
    this._permissionAdapter,
    this._activeEnterpriseId,
  );

  final CommissionRepository _repository;
  final OrangeMoneyTreasuryRepository _treasuryRepository;
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
    final commissionId = await _repository.createCommission(commission);
    if (commission.status == CommissionStatus.declared || 
        commission.status == CommissionStatus.paid) {
      await _recordTreasuryOperation(commission);
    }
    return commissionId;
  }

  Future<void> updateCommission(Commission commission) async {
    final oldCommission = await _repository.getCommission(commission.id);
    await _repository.updateCommission(commission);
    
    // If transitioning to a state that affects treasury (declared/validated/paid), record it
    final wasNotRecorded = oldCommission == null || 
        (oldCommission.status != CommissionStatus.declared && 
         oldCommission.status != CommissionStatus.paid);
    
    final isNowRecorded = commission.status == CommissionStatus.declared || 
                          commission.status == CommissionStatus.paid;

    if (wasNotRecorded && isNowRecorded) {
      await _recordTreasuryOperation(commission);
    }
  }

  Future<void> _recordTreasuryOperation(Commission commission) async {
    try {
      await _treasuryRepository.saveOperation(TreasuryOperation(
        id: IdGenerator.generate(),
        enterpriseId: commission.enterpriseId,
        userId: userId,
        amount: commission.finalAmount,
        type: TreasuryOperationType.supply,
        toAccount: PaymentMethod.mobileMoney,
        date: DateTime.now(),
        reason: 'Commission Orange Money - Période ${commission.period}',
        referenceEntityId: commission.id,
        referenceEntityType: 'commission',
      ));
    } catch (e) {
      AppLogger.error('Failed to record commission treasury operation', error: e);
    }
  }

  Future<void> deleteCommission(String commissionId) async {
    await _repository.deleteCommission(commissionId, userId);
    await _treasuryRepository.deleteOperationsByReference(commissionId, 'commission');
  }

  Future<void> restoreCommission(String commissionId) async {
    await _repository.restoreCommission(commissionId);
    final commission = await _repository.getCommission(commissionId);
    if (commission != null && commission.status == CommissionStatus.paid) {
      await _recordTreasuryOperation(commission);
    }
  }

  Stream<List<Commission>> watchDeletedCommissions() {
    return _repository.watchDeletedCommissions();
  }

  Future<Map<String, dynamic>> getStatistics({String? enterpriseId}) async {
    // If specific enterprise requested, use it
    if (enterpriseId != null) {
      return await _repository.getStatistics(enterpriseId: enterpriseId);
    }

    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    
    if (accessibleIds.length > 1) {
        return await _repository.fetchNetworkStatistics(accessibleIds.toList());
    }

    return await _repository.getStatistics(enterpriseId: _activeEnterpriseId);
  }

  Future<Map<String, dynamic>> getNetworkStatistics({String? period}) async {
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    return await _repository.fetchNetworkStatistics(accessibleIds.toList(), period: period);
  }

  Future<List<Commission>> fetchNetworkCommissions({String? period, CommissionStatus? status}) async {
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    return await _repository.fetchCommissionsByEnterprises(accessibleIds.toList(), period: period, status: status);
  }
}

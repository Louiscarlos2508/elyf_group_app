import '../../domain/entities/commission.dart';
import '../../domain/repositories/commission_repository.dart';

/// Controller for managing commissions.
class CommissionsController {
  CommissionsController(this._repository);

  final CommissionRepository _repository;

  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period,
  }) async {
    return await _repository.fetchCommissions(
      enterpriseId: enterpriseId,
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

  Future<Map<String, dynamic>> getStatistics({String? enterpriseId}) async {
    return await _repository.getStatistics(enterpriseId: enterpriseId);
  }
}

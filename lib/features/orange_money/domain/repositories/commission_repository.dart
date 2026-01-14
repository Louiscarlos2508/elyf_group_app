import '../entities/commission.dart';

/// Repository for managing commissions.
abstract class CommissionRepository {
  Future<List<Commission>> fetchCommissions({
    String? enterpriseId,
    CommissionStatus? status,
    String? period, // Format: "YYYY-MM"
  });

  Future<Commission?> getCommission(String commissionId);

  Future<Commission?> getCurrentMonthCommission(String enterpriseId);

  Future<String> createCommission(Commission commission);

  Future<void> updateCommission(Commission commission);

  /// Obtenir les statistiques des commissions.
  Future<Map<String, dynamic>> getStatistics({String? enterpriseId});
}

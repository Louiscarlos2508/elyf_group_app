import '../entities/audit_record.dart';

abstract class AuditTrailRepository {
  /// Fetches audit records for a specific enterprise.
  Future<List<AuditRecord>> fetchRecords({
    required String enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
    String? module,
    String? action,
    String? entityId,
    String? userId,
  });

  /// Fetches audit records for multiple enterprises.
  Future<List<AuditRecord>> fetchRecordsForEnterprises({
    required List<String> enterpriseIds,
    DateTime? startDate,
    DateTime? endDate,
    String? module,
    String? action,
    String? entityId,
    String? userId,
  });

  /// Saves a new audit record.
  Future<String> log(AuditRecord record);

  /// Deletes an audit record (usually only for maintenance/cleanup).
  ///
  /// Named `deleteRecord` to avoid clashing with [OfflineRepository.delete].
  Future<void> deleteRecord(String recordId, String enterpriseId);
}

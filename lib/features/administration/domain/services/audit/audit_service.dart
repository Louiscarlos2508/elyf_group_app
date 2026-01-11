import '../../../domain/entities/audit_log.dart';

/// Service for audit trail management.
/// 
/// Records all administrative actions for compliance and debugging.
abstract class AuditService {
  /// Log an administrative action
  Future<void> logAction({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String userId,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? moduleId,
    String? enterpriseId,
    String? userDisplayName,
  });

  /// Get audit logs for an entity
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  });

  /// Get audit logs for a user
  Future<List<AuditLog>> getLogsForUser(String userId);

  /// Get audit logs for a module
  Future<List<AuditLog>> getLogsForModule(String moduleId);

  /// Get audit logs for an enterprise
  Future<List<AuditLog>> getLogsForEnterprise(String enterpriseId);

  /// Get recent audit logs
  Future<List<AuditLog>> getRecentLogs({
    int limit = 50,
    DateTime? since,
  });
}


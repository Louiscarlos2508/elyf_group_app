import '../../domain/entities/audit_log.dart';
import '../../domain/services/audit/audit_service.dart';

/// Controller pour gérer l'audit trail.
/// 
/// Encapsule la logique métier pour l'audit trail.
class AuditController {
  AuditController(this._auditService);

  final AuditService _auditService;

  /// Récupère les logs d'audit récents.
  Future<List<AuditLog>> getRecentLogs({
    int limit = 50,
    DateTime? since,
  }) async {
    return await _auditService.getRecentLogs(limit: limit, since: since);
  }

  /// Récupère les logs pour une entité spécifique.
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  }) async {
    return await _auditService.getLogsForEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  /// Récupère les logs pour un utilisateur.
  Future<List<AuditLog>> getLogsForUser(String userId) async {
    return await _auditService.getLogsForUser(userId);
  }

  /// Récupère les logs pour un module.
  Future<List<AuditLog>> getLogsForModule(String moduleId) async {
    return await _auditService.getLogsForModule(moduleId);
  }

  /// Récupère les logs pour une entreprise.
  Future<List<AuditLog>> getLogsForEnterprise(String enterpriseId) async {
    return await _auditService.getLogsForEnterprise(enterpriseId);
  }

  /// Enregistre une action dans l'audit trail.
  /// 
  /// Cette méthode est principalement utilisée par les autres controllers.
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
  }) async {
    await _auditService.logAction(
      action: action,
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
      moduleId: moduleId,
      enterpriseId: enterpriseId,
    );
  }
}


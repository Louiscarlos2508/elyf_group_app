/// Audit log entry for tracking changes in the administration module.
/// 
/// Records who, what, when, and why for all administrative actions.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.userId,
    required this.timestamp,
    this.description,
    this.oldValue,
    this.newValue,
    this.moduleId,
    this.enterpriseId,
  });

  /// Unique identifier for the audit log entry
  final String id;

  /// Type of action performed (create, update, delete, assign, etc.)
  final AuditAction action;

  /// Type of entity affected (user, role, enterprise, etc.)
  final String entityType;

  /// ID of the affected entity
  final String entityId;

  /// ID of the user who performed the action
  final String userId;

  /// When the action was performed
  final DateTime timestamp;

  /// Optional description of the action
  final String? description;

  /// Optional old value before change
  final Map<String, dynamic>? oldValue;

  /// Optional new value after change
  final Map<String, dynamic>? newValue;

  /// Optional module ID if action is module-specific
  final String? moduleId;

  /// Optional enterprise ID if action is enterprise-specific
  final String? enterpriseId;

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action.name,
      'entityType': entityType,
      'entityId': entityId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      if (description != null) 'description': description,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (moduleId != null) 'moduleId': moduleId,
      if (enterpriseId != null) 'enterpriseId': enterpriseId,
    };
  }

  /// Create from Map
  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as String,
      action: AuditAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => AuditAction.unknown,
      ),
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      userId: map['userId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String?,
      oldValue: map['oldValue'] as Map<String, dynamic>?,
      newValue: map['newValue'] as Map<String, dynamic>?,
      moduleId: map['moduleId'] as String?,
      enterpriseId: map['enterpriseId'] as String?,
    );
  }
}

/// Types of audit actions
enum AuditAction {
  create,
  update,
  delete,
  assign,
  unassign,
  activate,
  deactivate,
  permissionChange,
  roleChange,
  unknown,
}


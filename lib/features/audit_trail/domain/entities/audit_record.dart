
enum AuditAction {
  create,
  update,
  delete,
  finalize,
  cancel,
  other
}

class AuditRecord {
  final String id;
  final String enterpriseId;
  final String userId;
  final String module; // e.g., 'orange_money', 'gaz', 'eau_minerale'
  final String action; // e.g., 'create_transaction', 'finalize_session'
  final String entityId; // ID of the affected entity
  final String entityType; // e.g., 'transaction', 'production_session'
  final Map<String, dynamic>? metadata; // Any additional info (diffs, amounts, etc.)
  final DateTime timestamp;
  final DateTime? updatedAt;

  const AuditRecord({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.module,
    required this.action,
    required this.entityId,
    required this.entityType,
    this.metadata,
    required this.timestamp,
    this.updatedAt,
  });


  AuditRecord copyWith({
    String? id,
    String? enterpriseId,
    String? userId,
    String? module,
    String? action,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    DateTime? updatedAt,
  }) {
    return AuditRecord(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      userId: userId ?? this.userId,
      module: module ?? this.module,
      action: action ?? this.action,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


enum MaintenancePriority { low, medium, high, critical }

enum MaintenanceStatus { open, inProgress, resolved, closed }

class MaintenanceTicket {
  MaintenanceTicket({
    required this.id,
    required this.enterpriseId,
    required this.propertyId,
    required this.description,
    required this.priority,
    required this.status,
    this.tenantId,
    this.assignedUserId,
    this.photos,
    this.cost,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String propertyId;
  final String? tenantId;
  final String? assignedUserId;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final List<String>? photos;
  final double? cost;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  MaintenanceTicket copyWith({
    String? id,
    String? enterpriseId,
    String? propertyId,
    String? tenantId,
    String? assignedUserId,
    String? description,
    MaintenancePriority? priority,
    MaintenanceStatus? status,
    List<String>? photos,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return MaintenanceTicket(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'assignedUserId': assignedUserId,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'photos': photos,
      'cost': cost,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  factory MaintenanceTicket.fromMap(Map<String, dynamic> map) {
    return MaintenanceTicket(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String,
      propertyId: map['propertyId'] as String,
      tenantId: map['tenantId'] as String?,
      assignedUserId: map['assignedUserId'] as String?,
      description: map['description'] as String,
      priority: MaintenancePriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => MaintenancePriority.medium,
      ),
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MaintenanceStatus.open,
      ),
      photos: (map['photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      cost: (map['cost'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceTicket &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

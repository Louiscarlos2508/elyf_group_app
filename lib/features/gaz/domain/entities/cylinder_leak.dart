/// Statut d'une bouteille avec fuite.
enum LeakStatus {
  reported('Signalée'),
  sentForExchange('Envoyée pour échange'),
  exchanged('Échangée');

  const LeakStatus(this.label);
  final String label;
}

/// Représente une bouteille avec fuite (échange standard fournisseur).
class CylinderLeak {
  const CylinderLeak({
    required this.id,
    required this.enterpriseId,
    required this.cylinderId,
    required this.weight,
    required this.reportedDate,
    required this.status,
    this.tourId,
    this.exchangeDate,
    this.notes,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String cylinderId;
  final int weight; // 3, 6, 10, 12
  final DateTime reportedDate;
  final LeakStatus status;
  final String?
  tourId; // ID du tour d'approvisionnement où la fuite a été signalée
  final DateTime? exchangeDate;
  final String? notes;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  CylinderLeak copyWith({
    String? id,
    String? enterpriseId,
    String? cylinderId,
    int? weight,
    DateTime? reportedDate,
    LeakStatus? status,
    String? tourId,
    DateTime? exchangeDate,
    String? notes,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CylinderLeak(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      cylinderId: cylinderId ?? this.cylinderId,
      weight: weight ?? this.weight,
      reportedDate: reportedDate ?? this.reportedDate,
      status: status ?? this.status,
      tourId: tourId ?? this.tourId,
      exchangeDate: exchangeDate ?? this.exchangeDate,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory CylinderLeak.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return CylinderLeak(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      cylinderId: map['cylinderId'] as String? ?? '',
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      reportedDate: map['reportedDate'] != null
          ? DateTime.parse(map['reportedDate'] as String)
          : DateTime.now(),
      status: LeakStatus.values.byName(map['status'] as String? ?? 'reported'),
      tourId: map['tourId'] as String?,
      exchangeDate: map['exchangeDate'] != null
          ? DateTime.parse(map['exchangeDate'] as String)
          : null,
      notes: map['notes'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'cylinderId': cylinderId,
      'weight': weight,
      'reportedDate': reportedDate.toIso8601String(),
      'status': status.name,
      'tourId': tourId,
      'exchangeDate': exchangeDate?.toIso8601String(),
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}

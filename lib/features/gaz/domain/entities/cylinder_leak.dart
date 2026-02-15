/// Statut d'une bouteille avec fuite.
enum LeakStatus {
  reported('Signalée'),
  sentForExchange('Envoyée pour échange'),
  exchanged('Échangée');

  const LeakStatus(this.label);
  final String label;
}

/// Source d'une fuite.
enum LeakSource {
  store('Magasin'),
  tour('Tournée (Livraison)'),
  supplier('Fournisseur (Réception)');

  const LeakSource(this.label);
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
    this.source = LeakSource.store,
    this.isFullLoss = true,
    this.estimatedLossVolume,
    this.tourId,
    this.exchangeDate,
    this.notes,
    this.reportedBy,
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
  final LeakSource source;
  final bool isFullLoss;
  final double? estimatedLossVolume;
  final String? notes;
  final String? reportedBy;
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
    LeakSource? source,
    bool? isFullLoss,
    double? estimatedLossVolume,
    String? tourId,
    DateTime? exchangeDate,
    String? notes,
    String? reportedBy,
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
      source: source ?? this.source,
      isFullLoss: isFullLoss ?? this.isFullLoss,
      estimatedLossVolume: estimatedLossVolume ?? this.estimatedLossVolume,
      tourId: tourId ?? this.tourId,
      exchangeDate: exchangeDate ?? this.exchangeDate,
      notes: notes ?? this.notes,
      reportedBy: reportedBy ?? this.reportedBy,
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
      source: map['source'] != null 
          ? LeakSource.values.byName(map['source'] as String)
          : LeakSource.store,
      isFullLoss: map['isFullLoss'] as bool? ?? true,
      estimatedLossVolume: (map['estimatedLossVolume'] as num?)?.toDouble(),
      tourId: map['tourId'] as String?,
      reportedBy: map['reportedBy'] as String?,
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
      'source': source.name,
      'isFullLoss': isFullLoss,
      'estimatedLossVolume': estimatedLossVolume,
      'tourId': tourId,
      'exchangeDate': exchangeDate?.toIso8601String(),
      'notes': notes,
      'reportedBy': reportedBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}

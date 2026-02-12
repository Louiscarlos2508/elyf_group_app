/// Représente un mouvement de stock pour une bobine (entrée ou sortie).
class BobineStockMovement {
  const BobineStockMovement({
    required this.id,
    required this.enterpriseId,
    required this.bobineId,
    required this.bobineReference,
    required this.type,
    required this.date,
    required this.quantite,
    required this.raison,
    this.productionId,
    this.machineId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String bobineId;
  final String bobineReference;
  final BobineMovementType type;
  final DateTime date;
  final double quantite; // En unités
  final String
  raison; // Ex: "Livraison", "Installation en production", "Retrait après fin"
  final String? productionId; // ID de la production si lié à une production
  final String? machineId; // ID de la machine si lié à une installation
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  BobineStockMovement copyWith({
    String? id,
    String? enterpriseId,
    String? bobineId,
    String? bobineReference,
    BobineMovementType? type,
    DateTime? date,
    double? quantite,
    String? raison,
    String? productionId,
    String? machineId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return BobineStockMovement(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      bobineId: bobineId ?? this.bobineId,
      bobineReference: bobineReference ?? this.bobineReference,
      type: type ?? this.type,
      date: date ?? this.date,
      quantite: quantite ?? this.quantite,
      raison: raison ?? this.raison,
      productionId: productionId ?? this.productionId,
      machineId: machineId ?? this.machineId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory BobineStockMovement.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return BobineStockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      bobineId: map['bobineId'] as String? ?? '',
      bobineReference: map['bobineReference'] as String? ?? '',
      type: BobineMovementType.values.byName(map['type'] as String? ?? 'entree'),
      date: DateTime.parse(map['date'] as String),
      quantite: (map['quantite'] as num?)?.toDouble() ?? 0,
      raison: map['raison'] as String? ?? '',
      productionId: map['productionId'] as String?,
      machineId: map['machineId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
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
      'bobineId': bobineId,
      'bobineReference': bobineReference,
      'type': type.name,
      'date': date.toIso8601String(),
      'quantite': quantite,
      'raison': raison,
      'productionId': productionId,
      'machineId': machineId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}

enum BobineMovementType {
  /// Entrée en stock (livraison)
  entree,

  /// Sortie du stock (installation en production)
  sortie,

  /// Retrait après utilisation complète
  retrait,
}

extension BobineMovementTypeExtension on BobineMovementType {
  String get label {
    switch (this) {
      case BobineMovementType.entree:
        return 'Entrée';
      case BobineMovementType.sortie:
        return 'Sortie';
      case BobineMovementType.retrait:
        return 'Retrait';
    }
  }
}

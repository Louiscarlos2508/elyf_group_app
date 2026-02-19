/// Représente un mouvement de stock pour les emballages (entrée ou sortie).
class PackagingStockMovement {
  const PackagingStockMovement({
    required this.id,
    required this.enterpriseId,
    required this.packagingId,
    required this.packagingType,
    required this.type,
    required this.date,
    required this.quantite,
    required this.raison,
    this.isInLots = false, // Vrai si la quantité saisie était en lots
    this.quantiteSaisie, // La quantité telle que saisie par l'utilisateur (lots ou unités)
    this.productionId,
    this.fournisseur,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String packagingId;
  final String packagingType;
  final PackagingMovementType type;
  final DateTime date;
  final int quantite; // Quantité en UNITÉS (toujours)
  final bool isInLots; // Vrai si saisi en lots
  final double? quantiteSaisie; // Quantité telle que saisie (supporte les décimales pour les lots)
  final String
  raison; // Ex: "Livraison", "Utilisation en production", "Ajustement"
  final String? productionId; // ID de la production si lié à une production
  final String? fournisseur; // Fournisseur si entrée
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  PackagingStockMovement copyWith({
    String? id,
    String? enterpriseId,
    String? packagingId,
    String? packagingType,
    PackagingMovementType? type,
    DateTime? date,
    int? quantite,
    bool? isInLots,
    double? quantiteSaisie,
    String? raison,
    String? productionId,
    String? fournisseur,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return PackagingStockMovement(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      packagingId: packagingId ?? this.packagingId,
      packagingType: packagingType ?? this.packagingType,
      type: type ?? this.type,
      date: date ?? this.date,
      quantite: quantite ?? this.quantite,
      isInLots: isInLots ?? this.isInLots,
      quantiteSaisie: quantiteSaisie ?? this.quantiteSaisie,
      raison: raison ?? this.raison,
      productionId: productionId ?? this.productionId,
      fournisseur: fournisseur ?? this.fournisseur,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory PackagingStockMovement.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return PackagingStockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      packagingId: map['packagingId'] as String? ?? '',
      packagingType: map['packagingType'] as String? ?? '',
      type: PackagingMovementType.values.byName(map['type'] as String? ?? 'entree'),
      date: DateTime.parse(map['date'] as String),
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      raison: map['raison'] as String? ?? '',
      isInLots: map['isInLots'] as bool? ?? false,
      quantiteSaisie: (map['quantiteSaisie'] as num?)?.toDouble(),
      productionId: map['productionId'] as String?,
      fournisseur: map['fournisseur'] as String?,
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
      'packagingId': packagingId,
      'packagingType': packagingType,
      'type': type.name,
      'date': date.toIso8601String(),
      'quantite': quantite,
      'raison': raison,
      'isInLots': isInLots,
      'quantiteSaisie': quantiteSaisie,
      'productionId': productionId,
      'fournisseur': fournisseur,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

enum PackagingMovementType {
  /// Entrée en stock (livraison)
  entree,

  /// Sortie du stock (utilisation en production)
  sortie,

  /// Ajustement manuel
  ajustement,
}

extension PackagingMovementTypeExtension on PackagingMovementType {
  String get label {
    switch (this) {
      case PackagingMovementType.entree:
        return 'Entrée';
      case PackagingMovementType.sortie:
        return 'Sortie';
      case PackagingMovementType.ajustement:
        return 'Ajustement';
    }
  }
}

class PackagingStock {
  const PackagingStock({
    required this.id,
    required this.enterpriseId,
    required this.type,
    required this.quantity,
    required this.unit,
    this.unitsPerLot = 1, // Par défaut, 1 unité par lot (si non défini)
    this.seuilAlerte,
    this.fournisseur,
    this.prixUnitaire,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  }) : assert(quantity >= 0, 'La quantité ne peut pas être négative'),
       assert(unitsPerLot > 0, 'Le nombre d\'unités par lot doit être positif'),
       assert(
         seuilAlerte == null || seuilAlerte >= 0,
         'Le seuil d\'alerte ne peut pas être négatif',
       );

  final String id;
  final String enterpriseId;
  final String type; // Type d'emballage (par défaut: "Emballage")
  final int quantity; // Quantité disponible (toujours en UNITÉS dans la base)
  final String unit; // Unité d'affichage (ex: "films", "sachets")
  final int unitsPerLot; // Nombre d'unités contenues dans un lot d'achat
  final int? seuilAlerte; // Seuil d'alerte pour stock faible (en UNITÉS)
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (CFA)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// Retourne la quantité exprimée en lots
  double get lotsRestants => quantity / unitsPerLot;

  /// Vérifie si le stock peut satisfaire une demande de [besoinEnUnites]
  bool peutSatisfaire(int besoinEnUnites) => quantity >= besoinEnUnites;

  /// Vérifie si le stock est faible
  bool get estStockFaible {
    if (seuilAlerte == null) return false;
    return quantity <= seuilAlerte!;
  }

  /// Retourne le pourcentage de stock restant par rapport au seuil (si applicable)
  /// ou une valeur relative pour l'affichage.
  double get pourcentageRestant {
    if (seuilAlerte == null || seuilAlerte == 0) return 1.0;
    return (quantity / (seuilAlerte! * 2)).clamp(0.0, 1.0);
  }

  /// Libellé formaté de la quantité
  String get quantityLabel {
    if (unitsPerLot <= 1) return '$quantity $unit';
    return '${lotsRestants.toStringAsFixed(1)} lots ($quantity $unit)';
  }

  bool get isDeleted => deletedAt != null;

  PackagingStock copyWith({
    String? id,
    String? enterpriseId,
    String? type,
    int? quantity,
    String? unit,
    int? unitsPerLot,
    int? seuilAlerte,
    String? fournisseur,
    int? prixUnitaire,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return PackagingStock(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitsPerLot: unitsPerLot ?? this.unitsPerLot,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      fournisseur: fournisseur ?? this.fournisseur,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory PackagingStock.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return PackagingStock(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      type: map['type'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      unitsPerLot: (map['unitsPerLot'] as num?)?.toInt() ?? 1,
      seuilAlerte: (map['seuilAlerte'] as num?)?.toInt(),
      fournisseur: map['fournisseur'] as String?,
      prixUnitaire: (map['prixUnitaire'] as num?)?.toInt(),
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
      'type': type,
      'quantity': quantity,
      'unit': unit,
      'unitsPerLot': unitsPerLot,
      'seuilAlerte': seuilAlerte,
      'fournisseur': fournisseur,
      'prixUnitaire': prixUnitaire,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

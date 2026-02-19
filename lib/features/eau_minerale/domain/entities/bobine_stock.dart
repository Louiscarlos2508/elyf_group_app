class BobineStock {
  const BobineStock({
    required this.id,
    required this.enterpriseId,
    this.productId, // ID du produit dans le catalogue
    required this.type,
    required this.quantity,
    required this.unit,
    this.unitsPerLot = 1,
    this.seuilAlerte,
    this.fournisseur,
    this.prixUnitaire,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  }) : assert(quantity >= 0, 'La quantité ne peut pas être négative'),
       assert(
         seuilAlerte == null || seuilAlerte >= 0,
         'Le seuil d\'alerte ne peut pas être négatif',
       );

  final String id;
  final String enterpriseId;
  final String? productId; // ID du produit dans le catalogue
  final String type; // Type de bobine (par défaut: "Bobine standard")
  final int quantity; // Quantité disponible
  final String unit; // Unité (ex: "unités", "bobines")
  final int unitsPerLot;
  final int? seuilAlerte; // Seuil d'alerte pour stock faible
  final String? fournisseur;
  final int? prixUnitaire; // Prix d'achat unitaire (CFA)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// Vérifie si le stock est faible (en dessous du seuil d'alerte)
  bool get estStockFaible {
    if (seuilAlerte == null) return false;
    return quantity <= seuilAlerte!;
  }

  bool get isDeleted => deletedAt != null;

  /// Vérifie si le stock peut satisfaire une demande de [besoinEnUnites]
  bool peutSatisfaire(int besoinEnUnites) => quantity >= besoinEnUnites;

  /// Retourne la quantité exprimée en lots
  double get lotsRestants => quantity / unitsPerLot;

  /// Libellé formaté de la quantité
  String get quantityLabel {
    if (unitsPerLot <= 1) return '$quantity $unit';
    return '${lotsRestants.toStringAsFixed(1)} lots ($quantity $unit)';
  }

  BobineStock copyWith({
    String? id,
    String? enterpriseId,
    String? productId,
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
    return BobineStock(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      productId: productId ?? this.productId,
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

  factory BobineStock.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return BobineStock(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      productId: map['productId'] as String?,
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
      'productId': productId,
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

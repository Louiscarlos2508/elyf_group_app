class BobineStock {
  const BobineStock({
    required this.id,
    required this.enterpriseId,
    required this.type,
    required this.quantity,
    required this.unit,
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
  final String type; // Type de bobine (par défaut: "Bobine standard")
  final int quantity; // Quantité disponible
  final String unit; // Unité (ex: "unités", "bobines")
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

  BobineStock copyWith({
    String? id,
    String? enterpriseId,
    String? type,
    int? quantity,
    String? unit,
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
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
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
      type: map['type'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
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

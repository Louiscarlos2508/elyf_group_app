/// Représente une bouteille de gaz.
class Cylinder {
  const Cylinder({
    required this.id,
    required this.weight,
    required this.buyPrice,
    required this.sellPrice,
    required this.enterpriseId,
    required this.moduleId,
    required this.moduleId,
    this.stock = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final int
  weight; // Poids en kg (dynamique, récupéré depuis les bouteilles créées)
  final double buyPrice;
  final double sellPrice;
  final String enterpriseId;
  final String moduleId;
  final int stock; // Stock disponible
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  Cylinder copyWith({
    String? id,
    int? weight,
    double? buyPrice,
    double? sellPrice,
    String? enterpriseId,
    String? moduleId,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Cylinder(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Cylinder.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Cylinder(
      id: map['id'] as String? ?? map['localId'] as String,
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      buyPrice: (map['buyPrice'] as num?)?.toDouble() ?? 0,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      moduleId: map['moduleId'] as String? ?? 'gaz',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
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
      'weight': weight,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'enterpriseId': enterpriseId,
      'moduleId': moduleId,
      'stock': stock,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;

  String get label {
    return '${weight}kg';
  }
}

/// Statut d'une bouteille dans le circuit logistique.
enum CylinderStatus {
  full('Pleines'),
  emptyAtStore('Vides (Magasin)'),
  emptyInTransit('Vides (En transit)'),
  defective('Défectueuses'),
  leak('Fuites');

  const CylinderStatus(this.label);
  final String label;
}

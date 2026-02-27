class Product {
  const Product({
    required this.id,
    required this.enterpriseId,
    required this.name,
    required this.type,
    required this.unitPrice,
    required this.unit,
    this.supplyUnit, // ex: "Paquet", "Rouleau"
    this.unitsPerLot = 1, // Conversion ratio (ex: 100 films per packet)
    this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String name;
  final ProductType type;
  final int unitPrice; // Price in CFA
  final String unit;
  final String? supplyUnit;
  final int unitsPerLot;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  Product copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    ProductType? type,
    int? unitPrice,
    String? unit,
    String? supplyUnit,
    int? unitsPerLot,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Product(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      type: type ?? this.type,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      supplyUnit: supplyUnit ?? this.supplyUnit,
      unitsPerLot: unitsPerLot ?? this.unitsPerLot,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Product(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String? ?? '',
      type: _parseType(map['type']),
      unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      supplyUnit: map['supplyUnit'] as String?,
      unitsPerLot: (map['unitsPerLot'] as num?)?.toInt() ?? 1,
      description: map['description'] as String?,
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
      'name': name,
      'type': type.name,
      'unitPrice': unitPrice,
      'unit': unit,
      'supplyUnit': supplyUnit,
      'unitsPerLot': unitsPerLot,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  static ProductType _parseType(dynamic value) {
    if (value == null) return ProductType.finishedGood;
    if (value is String) {
      try {
        return ProductType.values.byName(value);
      } catch (_) {
        return ProductType.finishedGood;
      }
    }
    return ProductType.finishedGood;
  }

  bool get isRawMaterial => type == ProductType.rawMaterial;
  bool get isFinishedGood => type == ProductType.finishedGood;
  bool get isDeleted => deletedAt != null;

  String get typeLabel => type == ProductType.rawMaterial ? 'MP' : 'PF';
  String get typeFullLabel =>
      type == ProductType.rawMaterial ? 'Matière Première' : 'Produit Fini';

  String get managementDescription {
    if (isRawMaterial) {
      return 'Géré manuellement • Utilisé en production';
    }
    return 'Ajouté par production • Déduit par ventes';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          enterpriseId == other.enterpriseId;

  @override
  int get hashCode => id.hashCode ^ enterpriseId.hashCode;
}

enum ProductType { rawMaterial, finishedGood }

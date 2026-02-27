/// Inventory snapshot for finished goods or raw materials.
class StockItem {
  const StockItem({
    required this.id,
    required this.enterpriseId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.type,
    required this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String name;
  final double quantity;
  final String unit;
  final StockType type;
  final DateTime updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  StockItem copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    double? quantity,
    String? unit,
    StockType? type,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return StockItem(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory StockItem.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return StockItem(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      type: StockType.values.byName(map['type'] as String? ?? 'finishedGoods'),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'type': type.name,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

enum StockType { finishedGoods, rawMaterial }

/// Represents a stock movement (entry or exit).
/// Unified model for displaying all stock movements from different sources.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.productName,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.unit,
    this.productionId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final String productName;
  final StockMovementType type;
  final String reason;
  final double quantity;
  final String unit;
  final String? productionId; // ID de la production si lié à une production
  final String? notes; // Notes additionnelles
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  StockMovement copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    String? productName,
    StockMovementType? type,
    String? reason,
    double? quantity,
    String? unit,
    String? productionId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return StockMovement(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      productionId: productionId ?? this.productionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory StockMovement.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return StockMovement(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String),
      productName: map['productName'] as String? ?? '',
      type: StockMovementType.values.byName(map['type'] as String? ?? 'entry'),
      reason: map['reason'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      productionId: map['productionId'] as String?,
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
      'date': date.toIso8601String(),
      'productName': productName,
      'type': type.name,
      'reason': reason,
      'quantity': quantity,
      'unit': unit,
      'productionId': productionId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;

  factory StockMovement.sample(int index) {
// ... (rest of class)
    final reasons = [
      'Production',
      'Vente',
      'Ajustement manuel',
      'Réception',
      'Perte',
    ];
    final products = ['Pack', 'Emballage', 'Bobine'];

    return StockMovement(
      id: 'movement-$index',
      enterpriseId: 'mock-enterprise',
      date: DateTime.now().subtract(Duration(days: index)),
      productName: products[index % products.length],
      type: index.isEven ? StockMovementType.entry : StockMovementType.exit,
      reason: reasons[index % reasons.length],
      quantity: (100 + index * 10).toDouble(),
      unit: 'unité',
    );
  }
}

enum StockMovementType { entry, exit }

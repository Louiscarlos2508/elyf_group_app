/// Represents a stock movement (entry or exit).
/// Unified model for displaying all stock movements from different sources.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.enterpriseId,
    required this.productId,
    required this.productName,
    required this.date,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.unit,
    this.quantityLabel,
    this.productionId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String productId;
  final String productName;
  final DateTime date;
  final StockMovementType type;
  final String reason;
  final double quantity;
  final String unit;
  final String? quantityLabel;
  final String? productionId; // ID de la production si lié à une production
  final String? notes; // Notes additionnelles
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  StockMovement copyWith({
    String? id,
    String? enterpriseId,
    String? productId,
    DateTime? date,
    String? productName,
    StockMovementType? type,
    String? reason,
    double? quantity,
    String? unit,
    String? quantityLabel,
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
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      date: date ?? this.date,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      quantityLabel: quantityLabel ?? this.quantityLabel,
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
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      type: StockMovementType.values.byName(map['type'] as String? ?? 'entry'),
      reason: map['reason'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      quantityLabel: map['quantityLabel'] as String?,
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
      'productId': productId,
      'productName': productName,
      'date': date.toIso8601String(),
      'type': type.name,
      'reason': reason,
      'quantity': quantity,
      'unit': unit,
      'quantityLabel': quantityLabel,
      'productionId': productionId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}

enum StockMovementType { entry, exit }

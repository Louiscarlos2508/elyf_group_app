
import 'package:equatable/equatable.dart';

enum StockMovementType {
  sale,
  purchase,
  adjustment,
  returnItem,
  initial,
}

class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.enterpriseId,
    required this.type,
    required this.quantity, // Positive for addition, negative for subtraction
    required this.balanceAfter,
    required this.date,
    required this.userId,
    this.referenceId, // ID of Sale, Purchase, etc.
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String productId;
  final String enterpriseId;
  final StockMovementType type;
  final int quantity;
  final int balanceAfter;
  final DateTime date;
  final String userId;
  final String? referenceId;
  final String? notes;
  final DateTime? deletedAt;

  StockMovement copyWith({
    String? id,
    String? productId,
    String? enterpriseId,
    StockMovementType? type,
    int? quantity,
    int? balanceAfter,
    DateTime? date,
    String? userId,
    String? referenceId,
    String? notes,
    DateTime? deletedAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'enterpriseId': enterpriseId,
      'type': type.name,
      'quantity': quantity,
      'balanceAfter': balanceAfter,
      'date': date.toIso8601String(),
      'userId': userId,
      'referenceId': referenceId,
      'notes': notes,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      productId: map['productId'] as String,
      enterpriseId: map['enterpriseId'] as String,
      type: StockMovementType.values.byName(map['type'] as String),
      quantity: (map['quantity'] as num).toInt(),
      balanceAfter: (map['balanceAfter'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      userId: map['userId'] as String,
      referenceId: map['referenceId'] as String?,
      notes: map['notes'] as String?,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        enterpriseId,
        type,
        quantity,
        balanceAfter,
        date,
        userId,
        referenceId,
        notes,
        deletedAt,
      ];
}

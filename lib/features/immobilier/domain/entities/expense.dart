import '../../../../shared/domain/entities/payment_method.dart';

/// Entité représentant une dépense liée à une propriété.
class PropertyExpense {
  PropertyExpense({
    required this.id,
    required this.enterpriseId,
    required this.propertyId,
    required this.amount,
    required this.expenseDate,
    required this.category,
    required this.description,
    this.paymentMethod = PaymentMethod.cash,
    this.property,
    this.receipt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String propertyId;
  final int amount;
  final DateTime expenseDate;
  final ExpenseCategory category;
  final String description;
  final PaymentMethod paymentMethod;
  final String? property;
  final String? receipt; // URL ou chemin vers le reçu
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  PropertyExpense copyWith({
    String? id,
    String? enterpriseId,
    String? propertyId,
    int? amount,
    DateTime? expenseDate,
    ExpenseCategory? category,
    String? description,
    PaymentMethod? paymentMethod,
    String? property,
    String? receipt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return PropertyExpense(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      propertyId: propertyId ?? this.propertyId,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      property: property ?? this.property,
      receipt: receipt ?? this.receipt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  /// Représentation sérialisable pour logs / audit trail / persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'propertyId': propertyId,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'category': category.name,
      'description': description,
      'paymentMethod': paymentMethod.name,
      'property': property,
      'receipt': receipt,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  factory PropertyExpense.fromMap(Map<String, dynamic> map) {
    return PropertyExpense(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String,
      propertyId: map['propertyId'] as String,
      amount: (map['amount'] as num).toInt(),
      expenseDate: DateTime.parse(map['expenseDate'] as String),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: map['description'] as String,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      property: map['property'] as String?,
      receipt: map['receipt'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyExpense &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum ExpenseCategory {
  maintenance,
  repair,
  utilities,
  insurance,
  taxes,
  cleaning,
  other,
}

/// Entité représentant une dépense liée à une propriété.
class PropertyExpense {
  PropertyExpense({
    required this.id,
    required this.propertyId,
    required this.amount,
    required this.expenseDate,
    required this.category,
    required this.description,
    this.property,
    this.receipt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String propertyId;
  final int amount;
  final DateTime expenseDate;
  final ExpenseCategory category;
  final String description;
  final String? property;
  final String? receipt; // URL ou chemin vers le reçu
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  PropertyExpense copyWith({
    String? id,
    String? propertyId,
    int? amount,
    DateTime? expenseDate,
    ExpenseCategory? category,
    String? description,
    String? property,
    String? receipt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return PropertyExpense(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      description: description ?? this.description,
      property: property ?? this.property,
      receipt: receipt ?? this.receipt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
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

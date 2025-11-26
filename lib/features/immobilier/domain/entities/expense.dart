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


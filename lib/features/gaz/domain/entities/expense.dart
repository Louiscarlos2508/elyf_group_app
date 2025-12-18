/// Représente une dépense liée à l'activité gaz.
class GazExpense {
  const GazExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.notes,
  });

  final String id;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String? notes;

  GazExpense copyWith({
    String? id,
    ExpenseCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    String? notes,
  }) {
    return GazExpense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

enum ExpenseCategory {
  transport('Transport'),
  maintenance('Maintenance'),
  salaries('Salaires'),
  rent('Loyer'),
  utilities('Services publics'),
  supplies('Fournitures'),
  other('Autre');

  const ExpenseCategory(this.label);
  final String label;
}

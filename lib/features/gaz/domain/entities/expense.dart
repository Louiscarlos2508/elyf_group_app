/// Représente une dépense liée à l'activité gaz.
class GazExpense {
  const GazExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.enterpriseId,
    required this.isFixed,
    this.notes,
    this.receiptPath,
  });

  final String id;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String enterpriseId;
  final bool isFixed; // Charge fixe vs variable
  final String? notes;
  final String? receiptPath;

  GazExpense copyWith({
    String? id,
    ExpenseCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    String? enterpriseId,
    bool? isFixed,
    String? notes,
    String? receiptPath,
  }) {
    return GazExpense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }
}

enum ExpenseCategory {
  maintenance('Maintenance'),
  structureCharges('Charges de structure'),
  salaries('Salaires'),
  loadingEvents('Frais de chargement'),
  transport('Transport'),
  rent('Loyer'),
  utilities('Services publics'),
  supplies('Fournitures'),
  other('Autre');

  const ExpenseCategory(this.label);
  final String label;
}

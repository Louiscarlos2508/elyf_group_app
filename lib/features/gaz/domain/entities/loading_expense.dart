/// Catégorie de dépense liée à un événement de chargement.
enum LoadingExpenseCategory {
  roadFee('Frais de route'),
  fuel('Carburant'),
  handling('Manutention'),
  miscellaneous('Imprévus');

  const LoadingExpenseCategory(this.label);
  final String label;
}

/// Représente une dépense liée à un événement de chargement.
class LoadingExpense {
  const LoadingExpense({
    required this.id,
    required this.loadingEventId,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
  });

  final String id;
  final String loadingEventId;
  final LoadingExpenseCategory category;
  final double amount;
  final String description;
  final DateTime expenseDate;

  LoadingExpense copyWith({
    String? id,
    String? loadingEventId,
    LoadingExpenseCategory? category,
    double? amount,
    String? description,
    DateTime? expenseDate,
  }) {
    return LoadingExpense(
      id: id ?? this.id,
      loadingEventId: loadingEventId ?? this.loadingEventId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
    );
  }
}
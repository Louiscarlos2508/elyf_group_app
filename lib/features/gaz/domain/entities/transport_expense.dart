/// Représente une dépense de transport.
class TransportExpense {
  const TransportExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime expenseDate;

  TransportExpense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? expenseDate,
  }) {
    return TransportExpense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
    );
  }
}


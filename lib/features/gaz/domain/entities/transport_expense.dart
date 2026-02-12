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

  factory TransportExpense.fromMap(Map<String, dynamic> map) {
    return TransportExpense(
      id: map['id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expenseDate'] != null
          ? DateTime.parse(map['expenseDate'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
    };
  }
}

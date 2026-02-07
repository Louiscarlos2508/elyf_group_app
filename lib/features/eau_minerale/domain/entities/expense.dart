/// Expense record with categorization.
class Expense {
  const Expense({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.receiptPath,
  });

  final String id;
  final String type;
  final int amount;
  final String description;
  final DateTime date;
  final String? receiptPath;
}

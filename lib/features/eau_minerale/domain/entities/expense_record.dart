/// Represents a charge associated with water production or distribution.
class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.label,
    required this.amountCfa,
    required this.category,
    required this.date,
  });

  final String id;
  final String label;
  final int amountCfa;
  final ExpenseCategory category;
  final DateTime date;

  factory ExpenseRecord.sample(int index) {
    return ExpenseRecord(
      id: 'expense-$index',
      label: index.isEven ? 'Fuel livraison' : 'Maintenance pompe',
      amountCfa: 15000 + (index * 7000),
      category: ExpenseCategory.values[index % ExpenseCategory.values.length],
      date: DateTime.now().subtract(Duration(days: index)),
    );
  }
}

enum ExpenseCategory { logistics, payroll, maintenance, utility }

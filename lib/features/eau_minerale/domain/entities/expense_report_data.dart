import 'expense_record.dart' show ExpenseCategory, ExpenseRecord;

/// Represents expense report data for a period.
class ExpenseReportData {
  const ExpenseReportData({
    required this.totalAmount,
    required this.expensesByCategory,
    required this.expenses,
  });

  final int totalAmount; // Total expenses
  final Map<ExpenseCategory, int> expensesByCategory; // Expenses grouped by category
  final List<ExpenseRecord> expenses; // List of expenses in period
}


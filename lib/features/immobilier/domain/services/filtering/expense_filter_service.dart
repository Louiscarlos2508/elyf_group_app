import '../../entities/expense.dart' show PropertyExpense;

/// Service for filtering expenses in Immobilier module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ExpenseFilterService {
  ExpenseFilterService();

  /// Filters expenses for today.
  List<PropertyExpense> filterTodayExpenses(
    List<PropertyExpense> expenses, [
    DateTime? referenceDate,
  ]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((e) {
      final expenseDate = DateTime(
        e.expenseDate.year,
        e.expenseDate.month,
        e.expenseDate.day,
      );
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calculates total for today's expenses.
  int calculateTodayTotal(List<PropertyExpense> expenses, [DateTime? referenceDate]) {
    final todayExpenses = filterTodayExpenses(expenses, referenceDate);
    return todayExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  /// Filters expenses by date range.
  List<PropertyExpense> filterByDateRange({
    required List<PropertyExpense> expenses,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return expenses.where((e) {
      if (startDate != null && e.expenseDate.isBefore(startDate)) return false;
      if (endDate != null && e.expenseDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }
}


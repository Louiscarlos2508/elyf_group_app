import '../../../../core/domain/entities/expense_balance_data.dart';
import '../../../../shared/domain/adapters/expense_balance_adapter.dart';
import '../entities/expense.dart';

/// Adaptateur pour convertir les Expense en ExpenseBalanceData.
class BoutiqueExpenseBalanceAdapter implements ExpenseBalanceAdapter {
  @override
  List<ExpenseBalanceData> convertToBalanceData(List<dynamic> expenses) {
    return (expenses as List<Expense>).map((expense) {
      return ExpenseBalanceData(
        id: expense.id,
        label: expense.label,
        amount: expense.amountCfa,
        category: expense.category.name,
        date: expense.date,
        description: expense.notes,
      );
    }).toList();
  }

  @override
  List<String> getCategories() {
    return ExpenseCategory.values.map((e) => e.name).toList();
  }

  @override
  String getCategoryLabel(String category) {
    switch (category) {
      case 'rent':
        return 'Loyer';
      case 'utilities':
        return 'Services publics';
      case 'maintenance':
        return 'Maintenance';
      case 'marketing':
        return 'Marketing';
      case 'other':
        return 'Autres';
      default:
        return category;
    }
  }
}

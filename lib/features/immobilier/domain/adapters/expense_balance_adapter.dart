import '../../../../core/domain/entities/expense_balance_data.dart';
import '../../../../shared/domain/adapters/expense_balance_adapter.dart';
import '../entities/expense.dart';

/// Adaptateur pour convertir les PropertyExpense en ExpenseBalanceData.
class ImmobilierExpenseBalanceAdapter implements ExpenseBalanceAdapter {
  @override
  List<ExpenseBalanceData> convertToBalanceData(List<dynamic> expenses) {
    return (expenses as List<PropertyExpense>).map((expense) {
      return ExpenseBalanceData(
        id: expense.id,
        label: expense.description,
        amount: expense.amount,
        category: expense.category.name,
        date: expense.expenseDate,
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
      case 'maintenance':
        return 'Maintenance';
      case 'repair':
        return 'Réparation';
      case 'utilities':
        return 'Services publics';
      case 'insurance':
        return 'Assurance';
      case 'taxes':
        return 'Taxes';
      case 'cleaning':
        return 'Nettoyage';
      case 'other':
        return 'Autres';
      default:
        return category;
    }
  }
}

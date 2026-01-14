import '../../../../core/domain/entities/expense_balance_data.dart';
import '../../../../shared/domain/adapters/expense_balance_adapter.dart';
import '../entities/expense_record.dart';

/// Adaptateur pour convertir les ExpenseRecord en ExpenseBalanceData.
class EauMineraleExpenseBalanceAdapter implements ExpenseBalanceAdapter {
  @override
  List<ExpenseBalanceData> convertToBalanceData(List<dynamic> expenses) {
    return (expenses as List<ExpenseRecord>).map((expense) {
      return ExpenseBalanceData(
        id: expense.id,
        label: expense.label,
        amount: expense.amountCfa,
        category: expense.category.name,
        date: expense.date,
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
      case 'logistics':
        return 'Logistique';
      case 'payroll':
        return 'Salaires';
      case 'maintenance':
        return 'Maintenance';
      case 'utility':
        return 'Services publics';
      default:
        return category;
    }
  }
}

import 'package:flutter/material.dart';

import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/entities/expense.dart';
import '../../../widgets/expenses_empty_state.dart';

/// Onglet dépenses par catégorie.
class ExpensesCategoryTab extends StatelessWidget {
  const ExpensesCategoryTab({
    super.key,
    required this.expenses,
  });

  final List<GazExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group expenses by category
    final expensesByCategory = <ExpenseCategory, List<GazExpense>>{};
    for (final expense in expenses) {
      expensesByCategory.putIfAbsent(expense.category, () => []).add(expense);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dépenses par catégorie',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: expensesByCategory.isEmpty
                ? const ExpensesEmptyState()
                : ListView.builder(
                    itemCount: expensesByCategory.length,
                    itemBuilder: (context, index) {
                      final category = expensesByCategory.keys.elementAt(index);
                      final categoryExpenses = expensesByCategory[category]!;
                      final categoryTotal = categoryExpenses.fold<double>(
                        0,
                        (sum, e) => sum + e.amount,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(category.label),
                          subtitle: Text('${categoryExpenses.length} dépense(s)'),
                          trailing: Text(
                            CurrencyFormatter.formatDouble(categoryTotal),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFFE7000B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


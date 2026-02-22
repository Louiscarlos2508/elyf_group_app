import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../domain/entities/expense.dart';
import '../../../widgets/expenses_empty_state.dart';

/// Onglet dépenses par catégorie.
class ExpensesCategoryTab extends StatelessWidget {
  const ExpensesCategoryTab({super.key, required this.expenses});

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dépenses par catégorie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            if (expensesByCategory.isEmpty)
              const ExpensesEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: expensesByCategory.length,
                itemBuilder: (context, index) {
                  final category = expensesByCategory.keys.elementAt(index);
                  final categoryExpenses = expensesByCategory[category]!;
                  final categoryTotal = categoryExpenses.fold<double>(
                    0,
                    (sum, e) => sum + e.amount,
                  );

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        category.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${categoryExpenses.length} dépense(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        CurrencyFormatter.formatDouble(categoryTotal),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

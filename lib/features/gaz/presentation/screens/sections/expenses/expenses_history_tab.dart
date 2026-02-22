import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../domain/entities/expense.dart';
import '../../../widgets/expenses_empty_state.dart';

/// Onglet historique des dépenses.
class ExpensesHistoryTab extends StatelessWidget {
  const ExpensesHistoryTab({
    super.key,
    required this.expenses,
    required this.onExpenseTap,
  });

  final List<GazExpense> expenses;
  final ValueChanged<GazExpense> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'Historique des dépenses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            if (expenses.isEmpty)
              const ExpensesEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: expenses.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      expense.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          '${expense.category.label} • ${expense.date.day}/${expense.date.month}/${expense.date.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (expense.receiptPath != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatDouble(expense.amount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onExpenseTap(expense),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/expense_record.dart';
import 'expenses_table_helpers.dart';

/// Mobile list view for expenses.
class ExpensesTableMobile extends StatelessWidget {
  const ExpensesTableMobile({
    super.key,
    required this.expenses,
    required this.formatCurrency,
    this.onActionTap,
  });

  final List<ExpenseRecord> expenses;
  final String Function(int) formatCurrency;
  final void Function(ExpenseRecord expense, String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ExpensesTableHelpers.buildCategoryChip(context, expense.category),
                  Text(
                    '${formatCurrency(expense.amountCfa)} FCFA',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (expense.estLieeAProduction)
                    Tooltip(
                      message: 'Liée à une production',
                      child: Icon(
                        Icons.factory,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ExpensesTableHelpers.buildActionButtons(
                context,
                expense,
                onActionTap,
              ),
            ],
          ),
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

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
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ElyfCard(
          isGlass: true,
          borderColor: Colors.red.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ExpensesTableHelpers.buildCategoryChip(
                    context,
                    expense.category,
                  ),
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

import 'package:flutter/material.dart';

import '../../domain/entities/expense_record.dart';
import 'expenses_table_desktop.dart';
import 'expenses_table_mobile.dart';

/// Table widget for displaying expenses list.
class ExpensesTable extends StatelessWidget {
  const ExpensesTable({
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

    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          'Aucune dépense enregistrée aujourd\'hui',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return ExpensesTableDesktop(
            expenses: expenses,
            formatCurrency: formatCurrency,
            onActionTap: onActionTap,
          );
        } else {
          return ExpensesTableMobile(
            expenses: expenses,
            formatCurrency: formatCurrency,
            onActionTap: onActionTap,
          );
        }
      },
    );
  }
}

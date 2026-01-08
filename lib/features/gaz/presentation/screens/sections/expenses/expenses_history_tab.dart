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
            'Historique des dépenses',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: expenses.isEmpty
                ? const ExpensesEmptyState()
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        title: Text(expense.description),
                        subtitle: Text(
                          '${expense.category.label} • ${expense.date.day}/${expense.date.month}/${expense.date.year}',
                        ),
                        trailing: Text(
                          CurrencyFormatter.formatDouble(expense.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFE7000B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => onExpenseTap(expense),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


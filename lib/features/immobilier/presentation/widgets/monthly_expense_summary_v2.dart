import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/expense.dart';

/// Widget displaying monthly expense summary for immobilier - style eau_minerale.
class MonthlyExpenseSummaryV2 extends StatelessWidget {
  const MonthlyExpenseSummaryV2({super.key, required this.expenses});

  final List<PropertyExpense> expenses;

  int _calculateMonthlyTotal() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthExpenses = expenses.where(
      (e) =>
          e.expenseDate.isAfter(monthStart.subtract(const Duration(days: 1))),
    );
    return monthExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  Map<ExpenseCategory, int> _getByCategory() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthExpenses = expenses.where(
      (e) =>
          e.expenseDate.isAfter(monthStart.subtract(const Duration(days: 1))),
    );

    final byCategory = <ExpenseCategory, int>{};
    for (final expense in monthExpenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }
    return byCategory;
  }

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.repair:
        return 'Réparation';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.insurance:
        return 'Assurance';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.cleaning:
        return 'Nettoyage';
      case ExpenseCategory.other:
        return 'Autres';
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return Colors.orange;
      case ExpenseCategory.repair:
        return Colors.red;
      case ExpenseCategory.utilities:
        return Colors.blue;
      case ExpenseCategory.insurance:
        return Colors.green;
      case ExpenseCategory.taxes:
        return Colors.purple;
      case ExpenseCategory.cleaning:
        return Colors.teal;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlyTotal = _calculateMonthlyTotal();
    final byCategory = _getByCategory();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Résumé Mensuel',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total ce mois', style: theme.textTheme.titleMedium),
                Text(
                  CurrencyFormatter.formatFCFA(monthlyTotal),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (byCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Par Catégorie',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...byCategory.entries.map((entry) {
              final percent = monthlyTotal > 0
                  ? (entry.value / monthlyTotal * 100).toStringAsFixed(0)
                  : '0';
              final color = _getCategoryColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getCategoryLabel(entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatFCFA(entry.value),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$percent%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

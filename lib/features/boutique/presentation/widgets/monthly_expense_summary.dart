import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/expense.dart';
import '../../domain/services/dashboard_calculation_service.dart';

/// Widget displaying monthly expense summary - style eau_minerale.
///
/// Uses [MonthlyExpenseMetrics] from the calculation service.
class MonthlyExpenseSummary extends StatelessWidget {
  const MonthlyExpenseSummary({
    super.key,
    required this.metrics,
    required this.calculationService,
  });

  /// Pre-calculated monthly expense metrics.
  final MonthlyExpenseMetrics metrics;

  /// Service for getting category labels.
  final BoutiqueDashboardCalculationService calculationService;

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.stock:
        return Colors.green;
      case ExpenseCategory.rent:
        return Colors.blue;
      case ExpenseCategory.utilities:
        return Colors.orange;
      case ExpenseCategory.maintenance:
        return Colors.purple;
      case ExpenseCategory.marketing:
        return Colors.teal;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlyTotal = metrics.totalAmount;
    final byCategory = metrics.byCategory;

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
                        calculationService.getCategoryLabel(entry.key),
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

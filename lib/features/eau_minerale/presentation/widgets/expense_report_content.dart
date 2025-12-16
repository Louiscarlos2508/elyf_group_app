import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/expense_report_data.dart';
import '../../domain/entities/report_period.dart';
import 'production_period_formatter.dart';

/// Content widget for expense report tab.
class ExpenseReportContent extends ConsumerWidget {
  const ExpenseReportContent({
    super.key,
    required this.period,
  });

  final ReportPeriod period;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.carburant:
        return Icons.local_gas_station;
      case ExpenseCategory.reparations:
        return Icons.build;
      case ExpenseCategory.achatsDivers:
        return Icons.shopping_cart;
      case ExpenseCategory.autres:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final reportAsync = ref.watch(reportExpenseProvider(period));

    return reportAsync.when(
      data: (data) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rapport des Dépenses',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${_formatCurrency(data.totalAmount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dépenses par Catégorie',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (data.expensesByCategory.isEmpty)
                Center(
                  child: Text(
                    'Aucune dépense pour cette période',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...data.expensesByCategory.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(entry.key),
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatCurrency(entry.value),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),
              Text(
                'Détail des Dépenses',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (data.expenses.isEmpty)
                Center(
                  child: Text(
                    'Aucune dépense enregistrée',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...data.expenses.map((expense) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          _getCategoryIcon(expense.category),
                          color: Colors.red,
                        ),
                        title: Text(expense.label),
                        subtitle: Text(ProductionPeriodFormatter.formatDate(expense.date)),
                        trailing: Text(
                          _formatCurrency(expense.amountCfa),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}


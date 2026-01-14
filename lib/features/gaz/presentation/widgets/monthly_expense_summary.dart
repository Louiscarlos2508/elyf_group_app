import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart'
    show gazReportCalculationServiceProvider;
import '../../domain/entities/expense.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';

/// Résumé mensuel des dépenses avec graphique par catégorie.
class GazMonthlyExpenseSummary extends ConsumerWidget {
  const GazMonthlyExpenseSummary({super.key, required this.expenses});

  final List<GazExpense> expenses;

  String _formatMonthYear(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.maintenance:
        return Colors.orange;
      case ExpenseCategory.salaries:
        return Colors.purple;
      case ExpenseCategory.rent:
        return Colors.brown;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.supplies:
        return Colors.teal;
      case ExpenseCategory.structureCharges:
        return Colors.indigo;
      case ExpenseCategory.loadingEvents:
        return Colors.cyan;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Utiliser le service de calcul pour extraire la logique métier
    final reportService = ref.read(gazReportCalculationServiceProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final expensesAnalysis = reportService.calculateExpensesAnalysis(
      expenses: expenses,
      startDate: monthStart,
      endDate: monthEnd,
    );
    final categoryTotals = expensesAnalysis.byCategory;
    final totalMonth = expensesAnalysis.totalAmount;
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Résumé du mois',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              _formatMonthYear(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total des dépenses',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatDouble(totalMonth),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${sortedCategories.length} catégories',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (sortedCategories.isNotEmpty) ...[
                const SizedBox(height: 24),
                // Progress bars by category
                ...sortedCategories.map((entry) {
                  final percentage = totalMonth > 0
                      ? (entry.value / totalMonth)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(entry.key),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              CurrencyFormatter.formatDouble(entry.value),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: _getCategoryColor(
                              entry.key,
                            ).withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              _getCategoryColor(entry.key),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Aucune dépense ce mois-ci',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

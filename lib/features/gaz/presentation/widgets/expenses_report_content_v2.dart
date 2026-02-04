import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/services/gaz_report_calculation_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';

/// Content widget for expenses report tab - style eau_minerale.
class GazExpensesReportContentV2 extends ConsumerWidget {
  const GazExpensesReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(gazExpensesProvider);
    final reportDataAsync = ref.watch(
      gazReportDataProvider(
        (period: GazReportPeriod.custom, startDate: startDate, endDate: endDate)
            as ({
              GazReportPeriod period,
              DateTime? startDate,
              DateTime? endDate,
            }),
      ),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: reportDataAsync.when(
        data: (reportData) {
          return expensesAsync.when(
            data: (expenses) {
              // Utiliser le service de calcul pour extraire la logique métier
              final reportService = ref.read(
                gazReportCalculationServiceProvider,
              );
              final expensesAnalysis = reportService.calculateExpensesAnalysis(
                expenses: expenses,
                startDate: startDate,
                endDate: endDate,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Détail des Dépenses',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${expensesAnalysis.totalExpenses} dépenses • Total: ${CurrencyFormatter.formatDouble(expensesAnalysis.totalAmount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Répartition par catégorie
                  Text(
                    'Répartition par Catégorie',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(
                    theme,
                    expensesAnalysis.byCategory,
                    expensesAnalysis.totalAmount,
                  ),

                  const SizedBox(height: 24),

                  // Statistiques
                  Text(
                    'Statistiques',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatistics(theme, expensesAnalysis),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    ThemeData theme,
    Map<ExpenseCategory, double> byCategory,
    double total,
  ) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Aucune dépense pour cette période',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: sorted.map((entry) {
        final percentage = total > 0 ? (entry.value / total) : 0.0;
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
                  Expanded(
                    child: Text(
                      entry.key.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
      }).toList(),
    );
  }

  Widget _buildStatistics(ThemeData theme, ExpensesAnalysis analysis) {
    if (analysis.totalExpenses == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moyenne',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(analysis.averageAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(analysis.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.maintenance:
        return const Color(0xFFF59E0B); // Amber
      case ExpenseCategory.salaries:
        return const Color(0xFF8B5CF6); // Violet
      case ExpenseCategory.rent:
        return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.utilities:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.supplies:
        return const Color(0xFF06B6D4); // Cyan
      case ExpenseCategory.structureCharges:
        return const Color(0xFF6366F1); // Indigo
      case ExpenseCategory.loadingEvents:
        return const Color(0xFF14B8A6); // Teal
      case ExpenseCategory.other:
        return const Color(0xFF64748B); // Slate
    }
  }
}

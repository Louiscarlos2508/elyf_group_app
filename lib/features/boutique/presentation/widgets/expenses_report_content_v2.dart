import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';

/// Content widget for expenses report tab - style eau_minerale.
class ExpensesReportContentV2 extends ConsumerWidget {
  const ExpensesReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final expensesReportAsync = ref.watch(
      expensesReportProvider((
        period: ReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: expensesReportAsync.when(
        data: (data) {
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
                '${data.expensesCount} dépenses • Total: ${_formatCurrency(data.totalAmount)}',
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
              _buildCategoryBreakdown(theme, data),

              const SizedBox(height: 24),

              // Statistiques
              Text(
                'Statistiques',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatistics(theme, data),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme, ExpensesReportData data) {
    if (data.byCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: data.byCategory.entries.map((entry) {
        // entry.key is String, we need to convert to category
        final categoryStr = entry.key;
        final color = _getCategoryColorFromString(categoryStr);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(entry.value),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColorFromString(String category) {
    switch (category.toLowerCase()) {
      case 'loyer':
        return Colors.blue;
      case 'services':
        return Colors.orange;
      case 'salaires':
        return Colors.purple;
      case 'transport':
        return Colors.teal;
      case 'entretien':
        return Colors.brown;
      case 'fournitures':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatistics(ThemeData theme, ExpensesReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow(theme, 'Nombre de dépenses', '${data.expensesCount}'),
          const Divider(),
          _buildStatRow(theme, 'Dépense moyenne', _formatCurrency(data.averageExpenseAmount)),
          const Divider(),
          _buildStatRow(theme, 'Total', _formatCurrency(data.totalAmount)),
        ],
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

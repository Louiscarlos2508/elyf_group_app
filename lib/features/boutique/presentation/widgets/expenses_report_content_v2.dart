import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
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
                '${data.expensesCount} dépenses • Total: ${CurrencyFormatter.formatFCFA(data.totalAmount)}',
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
        loading: () => const AppShimmers.list(count: 3),
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
        final color = _getCategoryColorFromString(theme, categoryStr);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
            ),
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
                CurrencyFormatter.formatFCFA(entry.value),
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

  Color _getCategoryColorFromString(ThemeData theme, String category) {
    switch (category.toLowerCase()) {
      case 'loyer':
        return const Color(0xFF3B82F6); // Blue
      case 'services':
        return const Color(0xFFF59E0B); // Amber
      case 'salaires':
        return const Color(0xFF8B5CF6); // Purple
      case 'transport':
        return const Color(0xFF10B981); // Emerald
      case 'entretien':
        return const Color(0xFFD97706); // Brown-ish
      case 'fournitures':
        return const Color(0xFF6366F1); // Indigo
      default:
        return theme.colorScheme.outline;
    }
  }

  Widget _buildStatistics(ThemeData theme, ExpensesReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _buildStatRow(theme, 'Nombre de dépenses', '${data.expensesCount}'),
          const Divider(),
          _buildStatRow(
            theme,
            'Dépense moyenne',
            CurrencyFormatter.formatFCFA(data.averageExpenseAmount),
          ),
          const Divider(),
          _buildStatRow(
            theme,
            'Total',
            CurrencyFormatter.formatFCFA(data.totalAmount),
          ),
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

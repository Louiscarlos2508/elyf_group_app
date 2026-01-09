import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'dashboard_kpi_card.dart';

/// Content widget for profit report tab - style eau_minerale.
class ProfitReportContentV2 extends ConsumerWidget {
  const ProfitReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final profitReportAsync = ref.watch(
      profitReportProvider((
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
      child: profitReportAsync.when(
        data: (data) {
          final isProfitable = data.netProfit >= 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Analyse de Rentabilité',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProfitable
                    ? 'Votre boutique est rentable sur cette période'
                    : 'Attention: Déficit sur cette période',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isProfitable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Résumé financier
              _buildFinancialSummary(theme, data, isWide),

              const SizedBox(height: 24),

              // Détail des calculs
              Text(
                'Détail des Calculs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCalculationDetail(theme, data),

              const SizedBox(height: 24),

              // Marge brute
              Text(
                'Indicateurs de Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPerformanceIndicators(theme, data, isWide),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFinancialSummary(
    ThemeData theme,
    ProfitReportData data,
    bool isWide,
  ) {
    final isProfitable = data.netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfitable
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isProfitable ? Icons.trending_up : Icons.trending_down,
            size: 48,
            color: isProfitable ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Bénéfice Net',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatFCFA(data.netProfit),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isProfitable ? Colors.green : Colors.red)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Marge: ${data.netMarginPercentage.toStringAsFixed(1)}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationDetail(ThemeData theme, ProfitReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildCalculationRow(
            theme,
            'Chiffre d\'Affaires',
            data.totalRevenue,
            Colors.blue,
            isPositive: true,
          ),
          const Divider(),
          _buildCalculationRow(
            theme,
            'Coût des Achats',
            data.totalCostOfGoodsSold,
            Colors.orange,
            isPositive: false,
          ),
          _buildCalculationRow(
            theme,
            'Dépenses',
            data.totalExpenses,
            Colors.red,
            isPositive: false,
          ),
          const Divider(thickness: 2),
          _buildCalculationRow(
            theme,
            'Bénéfice Net',
            data.netProfit,
            data.netProfit >= 0 ? Colors.green : Colors.red,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    ThemeData theme,
    String label,
    int amount,
    Color color, {
    bool isPositive = true,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium,
          ),
          Text(
            '${isPositive ? '+' : '-'} ${CurrencyFormatter.formatFCFA(amount.abs())}',
            style: (isTotal
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(
    ThemeData theme,
    ProfitReportData data,
    bool isWide,
  ) {
    final cards = [
      DashboardKpiCard(
        label: 'Marge Brute',
        value: CurrencyFormatter.formatFCFA(data.grossProfit),
        subtitle: '${data.grossMarginPercentage.toStringAsFixed(1)}% du CA',
        icon: Icons.show_chart,
        iconColor: Colors.purple,
        backgroundColor: Colors.purple,
      ),
      DashboardKpiCard(
        label: 'Marge Nette',
        value: '${data.netMarginPercentage.toStringAsFixed(1)}%',
        subtitle: 'après charges',
        icon: Icons.percent,
        iconColor: Colors.teal,
        backgroundColor: Colors.teal,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
        ],
      );
    }

    return Column(
      children: [
        cards[0],
        const SizedBox(height: 16),
        cards[1],
      ],
    );
  }
}

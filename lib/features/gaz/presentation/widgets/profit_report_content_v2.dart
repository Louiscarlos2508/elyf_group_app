import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'dashboard_kpi_card.dart';

/// Content widget for profit report tab - style eau_minerale.
class GazProfitReportContentV2 extends ConsumerWidget {
  const GazProfitReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    return (isNegative ? '-' : '') +
        absAmount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]} ',
            ) +
        ' F';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      ) as ({
          GazReportPeriod period,
          DateTime? startDate,
          DateTime? endDate,
        })),
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
      child: reportDataAsync.when(
        data: (data) {
          final isProfitable = data.profit >= 0;

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
                    ? 'Votre activité est rentable sur cette période'
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

              // Indicateurs de performance
              Text(
                'Indicateurs de Performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPerformanceIndicators(theme, data),
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
    GazReportData data,
    bool isWide,
  ) {
    final isProfitable = data.profit >= 0;

    return isWide
        ? Row(
            children: [
              Expanded(
                child: GazDashboardKpiCard(
                  label: "Chiffre d'Affaires",
                  value: _formatCurrency(data.salesRevenue),
                  icon: Icons.trending_up,
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GazDashboardKpiCard(
                  label: 'Dépenses',
                  value: _formatCurrency(data.expensesAmount),
                  icon: Icons.receipt_long,
                  iconColor: Colors.red,
                  backgroundColor: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GazDashboardKpiCard(
                  label: 'Bénéfice Net',
                  value: _formatCurrency(data.profit),
                  subtitle: isProfitable ? 'Profit' : 'Déficit',
                  icon: Icons.account_balance_wallet,
                  iconColor: isProfitable ? Colors.green : Colors.red,
                  valueColor: isProfitable
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  backgroundColor: isProfitable ? Colors.green : Colors.red,
                ),
              ),
            ],
          )
        : Column(
            children: [
              GazDashboardKpiCard(
                label: "Chiffre d'Affaires",
                value: _formatCurrency(data.salesRevenue),
                icon: Icons.trending_up,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: 16),
              GazDashboardKpiCard(
                label: 'Dépenses',
                value: _formatCurrency(data.expensesAmount),
                icon: Icons.receipt_long,
                iconColor: Colors.red,
                backgroundColor: Colors.red,
              ),
              const SizedBox(height: 16),
              GazDashboardKpiCard(
                label: 'Bénéfice Net',
                value: _formatCurrency(data.profit),
                subtitle: isProfitable ? 'Profit' : 'Déficit',
                icon: Icons.account_balance_wallet,
                iconColor: isProfitable ? Colors.green : Colors.red,
                valueColor: isProfitable
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                backgroundColor: isProfitable ? Colors.green : Colors.red,
              ),
            ],
          );
  }

  Widget _buildCalculationDetail(ThemeData theme, GazReportData data) {
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
            "Chiffre d'Affaires",
            _formatCurrency(data.salesRevenue),
            Colors.blue,
          ),
          const Divider(),
          _buildCalculationRow(
            theme,
            'Dépenses',
            _formatCurrency(data.expensesAmount),
            Colors.red,
          ),
          const Divider(),
          _buildCalculationRow(
            theme,
            'Bénéfice Net',
            _formatCurrency(data.profit),
            data.profit >= 0 ? Colors.green : Colors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    ThemeData theme,
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(
    ThemeData theme,
    GazReportData data,
  ) {
    final marginPercentage = data.profitMarginPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildIndicatorRow(
            theme,
            'Taux de Marge',
            '${marginPercentage.toStringAsFixed(2)}%',
            marginPercentage >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow(
            theme,
            'Nombre de Ventes',
            '${data.salesCount}',
            theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow(
            theme,
            'Nombre de Dépenses',
            '${data.expensesCount}',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sale.dart';
import '../../domain/services/profitability_calculation_service.dart';
import 'production_period_formatter.dart';
import 'profitability/financial_summary_card.dart';
import 'profitability/kpi_grid.dart';
import 'profitability/kpi_item.dart';
import 'profitability/product_profit_card.dart';

/// Widget displaying profitability analysis report.
class ProfitabilityReportContent extends ConsumerWidget {
  const ProfitabilityReportContent({
    super.key,
    required this.period,
  });

  final ReportPeriod period;)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(productionSessionsStateProvider);
    final salesAsync = ref.watch(reportSalesProvider(period));
    final expensesAsync = ref.watch(financesStateProvider);

    return sessionsAsync.when(
      data: (allSessions) {
        final sessions = allSessions.where((s) {
          return s.date
                  .isAfter(period.startDate.subtract(const Duration(days: 1))) &&
              s.date.isBefore(period.endDate.add(const Duration(days: 1)));
        }).toList();

        return salesAsync.when(
          data: (sales) {
            return expensesAsync.when(
              data: (finances) {
                final expenses = finances.expenses.where((e) {
                  return e.date.isAfter(
                          period.startDate.subtract(const Duration(days: 1))) &&
                      e.date
                          .isBefore(period.endDate.add(const Duration(days: 1)));
                }).toList();

                return _buildContent(
                  context,
                  ref,
                  theme,
                  sessions,
                  sales,
                  expenses.fold<int>(0, (sum, e) => sum + e.amountCfa),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<ProductionSession> sessions,
    List<Sale> sales,
    int totalExpenses,
  ) {
    // Use profitability calculation service
    final calculationService = ref.read(profitabilityCalculationServiceProvider);
    final metrics = calculationService.calculateMetrics(
      sessions: sessions,
      sales: sales,
      totalExpenses: totalExpenses,
    );
    final productAnalysis = calculationService.analyzeByProduct(sales);

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
          _buildHeader(theme),
          const SizedBox(height: 24),
          _buildKpiSection(metrics),
          const SizedBox(height: 32),
          _buildProductSection(theme, productAnalysis),
          const SizedBox(height: 32),
          FinancialSummaryCard(
            totalRevenue: metrics.totalRevenue,
            totalProductionCost: metrics.totalProductionCost,
            totalExpenses: totalExpenses,
            grossProfit: metrics.grossProfit,
            formatCurrency: CurrencyFormatter.formatFCFA,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse de Rentabilité',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${ProductionPeriodFormatter.formatDate(period.startDate)} - '
          '${ProductionPeriodFormatter.formatDate(period.endDate)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiSection(ProfitabilityMetrics metrics) {
    return KpiGrid(
      items: [
        KpiItem(
          label: 'Coût de revient unitaire',
          value: '${metrics.costPerUnit.toStringAsFixed(2)} FCFA',
          icon: Icons.calculate,
          color: Colors.orange,
        ),
        KpiItem(
          label: 'Prix de vente moyen',
          value: '${metrics.avgSalePrice.toStringAsFixed(2)} FCFA',
          icon: Icons.sell,
          color: Colors.blue,
        ),
        KpiItem(
          label: 'Marge unitaire',
          value: '${metrics.marginPerUnit.toStringAsFixed(2)} FCFA',
          icon: Icons.trending_up,
          color: metrics.marginPerUnit >= 0 ? Colors.green : Colors.red,
        ),
        KpiItem(
          label: 'Marge brute globale',
          value: CurrencyFormatter.formatFCFA(metrics.grossProfit),
          icon: Icons.account_balance,
          color: metrics.grossProfit >= 0 ? Colors.green : Colors.red,
        ),
        KpiItem(
          label: 'Taux de marge',
          value: '${metrics.grossMarginPercent.toStringAsFixed(1)}%',
          icon: Icons.percent,
          color: metrics.grossMarginPercent >= 20 ? Colors.green : Colors.orange,
        ),
        KpiItem(
          label: 'Coûts totaux',
          value: CurrencyFormatter.formatFCFA(metrics.totalCosts),
          icon: Icons.receipt_long,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildProductSection(
    ThemeData theme,
    List<ProductProfitAnalysis> productAnalysis,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rentabilité par Produit',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (productAnalysis.isEmpty)
          Center(
            child: Text(
              'Aucune vente pour cette période',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...productAnalysis.map((product) => ProductProfitCard(
                productName: product.productName,
                quantity: product.quantity,
                revenue: product.revenue,
                estimatedCost: product.estimatedCost,
                margin: product.margin,
                marginPercent: product.marginPercent,
                formatCurrency: CurrencyFormatter.formatFCFA,
              )),
      ],
    );
  }

}

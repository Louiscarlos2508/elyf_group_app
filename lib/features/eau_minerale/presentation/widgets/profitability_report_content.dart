import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sale.dart';
import 'production_period_formatter.dart';

/// Widget displaying profitability analysis report.
class ProfitabilityReportContent extends ConsumerWidget {
  const ProfitabilityReportContent({
    super.key,
    required this.period,
  });

  final ReportPeriod period;

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
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
    ThemeData theme,
    List<ProductionSession> sessions,
    List<Sale> sales,
    int totalExpenses,
  ) {
    // Calculs de rentabilité
    final totalProduction =
        sessions.fold<int>(0, (sum, s) => sum + s.quantiteProduite);
    final totalProductionCost =
        sessions.fold<int>(0, (sum, s) => sum + s.coutTotal);
    final totalRevenue = sales.fold<int>(0, (sum, s) => sum + s.totalPrice);
    final totalSalesQuantity =
        sales.fold<int>(0, (sum, s) => sum + s.quantity);

    // Coût de revient unitaire
    final costPerUnit =
        totalProduction > 0 ? totalProductionCost / totalProduction : 0.0;

    // Prix de vente moyen
    final avgSalePrice =
        totalSalesQuantity > 0 ? totalRevenue / totalSalesQuantity : 0.0;

    // Marge brute unitaire
    final marginPerUnit = avgSalePrice - costPerUnit;

    // Marge globale
    final totalCosts = totalProductionCost + totalExpenses;
    final grossProfit = totalRevenue - totalCosts;
    final grossMarginPercent =
        totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;

    // Analyse par produit
    final productAnalysis = _analyzeByProduct(sales);

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
          const SizedBox(height: 24),

          // KPIs de rentabilité
          _KpiGrid(
            items: [
              _KpiItem(
                label: 'Coût de revient unitaire',
                value: '${costPerUnit.toStringAsFixed(2)} FCFA',
                icon: Icons.calculate,
                color: Colors.orange,
              ),
              _KpiItem(
                label: 'Prix de vente moyen',
                value: '${avgSalePrice.toStringAsFixed(2)} FCFA',
                icon: Icons.sell,
                color: Colors.blue,
              ),
              _KpiItem(
                label: 'Marge unitaire',
                value: '${marginPerUnit.toStringAsFixed(2)} FCFA',
                icon: Icons.trending_up,
                color: marginPerUnit >= 0 ? Colors.green : Colors.red,
              ),
              _KpiItem(
                label: 'Marge brute globale',
                value: _formatCurrency(grossProfit.toInt()),
                icon: Icons.account_balance,
                color: grossProfit >= 0 ? Colors.green : Colors.red,
              ),
              _KpiItem(
                label: 'Taux de marge',
                value: '${grossMarginPercent.toStringAsFixed(1)}%',
                icon: Icons.percent,
                color: grossMarginPercent >= 20 ? Colors.green : Colors.orange,
              ),
              _KpiItem(
                label: 'Coûts totaux',
                value: _formatCurrency(totalCosts),
                icon: Icons.receipt_long,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Analyse par produit
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
            ...productAnalysis.map((product) => _ProductProfitCard(
                  productName: product['name'] as String,
                  quantity: product['quantity'] as int,
                  revenue: product['revenue'] as int,
                  estimatedCost: product['estimatedCost'] as int,
                  margin: product['margin'] as int,
                  marginPercent: product['marginPercent'] as double,
                  formatCurrency: _formatCurrency,
                )),

          const SizedBox(height: 32),

          // Résumé financier
          _FinancialSummaryCard(
            totalRevenue: totalRevenue,
            totalProductionCost: totalProductionCost,
            totalExpenses: totalExpenses,
            grossProfit: grossProfit.toInt(),
            formatCurrency: _formatCurrency,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _analyzeByProduct(List<Sale> sales) {
    final byProduct = <String, Map<String, dynamic>>{};

    for (final sale in sales) {
      final name = sale.productName;
      if (!byProduct.containsKey(name)) {
        byProduct[name] = {
          'name': name,
          'quantity': 0,
          'revenue': 0,
        };
      }
      byProduct[name]!['quantity'] =
          (byProduct[name]!['quantity'] as int) + sale.quantity;
      byProduct[name]!['revenue'] =
          (byProduct[name]!['revenue'] as int) + sale.totalPrice;
    }

    // Estimer le coût et calculer la marge
    return byProduct.values.map((product) {
      final revenue = product['revenue'] as int;
      // Estimation du coût (75% du prix de vente comme estimation)
      final estimatedCost = (revenue * 0.75).toInt();
      final margin = revenue - estimatedCost;
      final marginPercent = revenue > 0 ? (margin / revenue) * 100 : 0.0;

      return {
        ...product,
        'estimatedCost': estimatedCost,
        'margin': margin,
        'marginPercent': marginPercent,
      };
    }).toList()
      ..sort((a, b) =>
          (b['margin'] as int).compareTo(a['margin'] as int));
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});

  final List<_KpiItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          );
        } else {
          return Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: item,
                    ))
                .toList(),
          );
        }
      },
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductProfitCard extends StatelessWidget {
  const _ProductProfitCard({
    required this.productName,
    required this.quantity,
    required this.revenue,
    required this.estimatedCost,
    required this.margin,
    required this.marginPercent,
    required this.formatCurrency,
  });

  final String productName;
  final int quantity;
  final int revenue;
  final int estimatedCost;
  final int margin;
  final double marginPercent;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = margin >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${marginPercent.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: 'Quantité',
                    value: '$quantity unités',
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'CA',
                    value: formatCurrency(revenue),
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'Marge',
                    value: formatCurrency(margin),
                    valueColor: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.totalRevenue,
    required this.totalProductionCost,
    required this.totalExpenses,
    required this.grossProfit,
    required this.formatCurrency,
  });

  final int totalRevenue;
  final int totalProductionCost;
  final int totalExpenses;
  final int grossProfit;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé Financier',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Chiffre d\'affaires',
            value: formatCurrency(totalRevenue),
            color: Colors.blue,
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Coûts de production',
            value: '- ${formatCurrency(totalProductionCost)}',
            color: Colors.orange,
          ),
          _SummaryRow(
            label: 'Autres dépenses',
            value: '- ${formatCurrency(totalExpenses)}',
            color: Colors.red,
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Résultat',
            value: formatCurrency(grossProfit),
            color: grossProfit >= 0 ? Colors.green : Colors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
}

import 'package:flutter/material.dart';

/// Card displaying a financial summary with revenue, costs and profit.
class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({
    super.key,
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


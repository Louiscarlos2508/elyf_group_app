import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';

/// Carte résumé financier (revenus, dépenses, reliquat).
class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({
    super.key,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netAmount,
  });

  final double totalRevenue;
  final double totalExpenses;
  final double netAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Résumé Financier',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _FinancialRow(
                label: 'Revenus',
                amount: totalRevenue,
                color: const Color(0xFF10B981), // Emerald
                formatCurrency: CurrencyFormatter.formatDouble,
              ),
              const SizedBox(height: 12),
              _FinancialRow(
                label: 'Dépenses',
                amount: totalExpenses,
                color: theme.colorScheme.error,
                formatCurrency: CurrencyFormatter.formatDouble,
              ),
              const Divider(height: 32),
              _FinancialRow(
                label: 'Reliquat Net (Siège)',
                amount: netAmount,
                color: netAmount >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
                formatCurrency: CurrencyFormatter.formatDouble,
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.formatCurrency,
    this.isBold = false,
  });

  final String label;
  final double amount;
  final Color color;
  final String Function(double) formatCurrency;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          formatCurrency(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

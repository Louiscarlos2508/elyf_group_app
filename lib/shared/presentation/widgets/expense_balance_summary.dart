import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared.dart';

/// Widget pour afficher le résumé du bilan des dépenses.
class ExpenseBalanceSummary extends StatelessWidget {
  const ExpenseBalanceSummary({
    super.key,
    required this.totalAmount,
    required this.expenseCount,
    required this.startDate,
    required this.endDate,
  });

  final int totalAmount;
  final int expenseCount;
  final DateTime startDate;
  final DateTime endDate;

  String _formatCurrency(int amount) {
    return CurrencyFormatter.formatFCFA(amount);
  }

  String _formatDateRange() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total dépenses',
                    _formatCurrency(totalAmount),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Nombre de dépenses',
                    expenseCount.toString(),
                    Icons.receipt_long,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Période: ${_formatDateRange()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


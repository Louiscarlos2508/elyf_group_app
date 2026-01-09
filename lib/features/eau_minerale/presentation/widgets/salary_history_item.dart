import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import 'salary_history_item_data.dart';

/// Item widget for displaying a payment in history.
class SalaryHistoryItem extends StatelessWidget {
  const SalaryHistoryItem({
    super.key,
    required this.payment,
  });

  final SalaryHistoryItemData payment;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  IconData _getIcon() {
    switch (payment.type) {
      case SalaryPaymentType.monthly:
        return Icons.account_circle;
      case SalaryPaymentType.production:
        return Icons.factory;
    }
  }

  Color _getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (payment.type) {
      case SalaryPaymentType.monthly:
        return Colors.blue;
      case SalaryPaymentType.production:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(_getIcon(), color: color),
        ),
        title: Text(payment.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment.period != null) ...[
              Text(
                payment.period!,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              _formatDate(payment.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.formatFCFA(payment.amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}


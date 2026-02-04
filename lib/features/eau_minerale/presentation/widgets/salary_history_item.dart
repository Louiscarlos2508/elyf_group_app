import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_payment.dart';
import '../../application/services/payment_receipt_generator.dart';

import 'salary_history_item_data.dart';

/// Item widget for displaying a payment in history with print option.
class SalaryHistoryItem extends StatelessWidget {
  const SalaryHistoryItem({super.key, required this.payment});

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
    switch (payment.type) {
      case SalaryPaymentType.monthly:
        return Colors.blue;
      case SalaryPaymentType.production:
        return Colors.purple;
    }
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      if (payment.originalPayment is SalaryPayment) {
        await PaymentReceiptGenerator.generateMonthlyReceipt(payment.originalPayment as SalaryPayment);
      } else if (payment.originalPayment is ProductionPayment) {
        await PaymentReceiptGenerator.generateProductionReceipt(payment.originalPayment as ProductionPayment);
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur lors de la génération du reçu: $e');
      }
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
              Text(payment.period!, style: theme.textTheme.bodySmall),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatFCFA(payment.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.print_rounded),
              onPressed: () => _printReceipt(context),
              tooltip: 'Imprimer le reçu',
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

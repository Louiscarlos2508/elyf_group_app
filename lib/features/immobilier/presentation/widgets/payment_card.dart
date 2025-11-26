import 'package:flutter/material.dart';

import '../../domain/entities/payment.dart';
import 'payment_card_actions.dart';
import 'payment_card_helpers.dart';

/// Carte réutilisable pour afficher un paiement.
class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
  });

  final Payment payment;
  final VoidCallback? onTap;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PaymentCardHelpers.getStatusColor(payment.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PaymentCardHelpers.getMethodIcon(payment.paymentMethod),
                      color: PaymentCardHelpers.getStatusColor(payment.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PaymentCardHelpers.formatCurrency(payment.amount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PaymentCardHelpers.formatDate(payment.paymentDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      PaymentCardHelpers.getStatusLabel(payment.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PaymentCardHelpers.getStatusColor(payment.status),
                      ),
                    ),
                    backgroundColor: PaymentCardHelpers
                        .getStatusColor(payment.status)
                        .withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    PaymentCardHelpers.getMethodLabel(payment.paymentMethod),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (payment.receiptNumber != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.receipt,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reçu: ${payment.receiptNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (payment.month != null && payment.year != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${PaymentCardHelpers.getMonthName(payment.month!)} ${payment.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              PaymentCardActions(payment: payment),
            ],
          ),
        ),
      ),
    );
  }

}


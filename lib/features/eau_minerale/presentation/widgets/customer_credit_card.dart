import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart'
    show CustomerSummary;
import 'credit_action_buttons.dart';
import 'customer_credit_header.dart';
import 'customer_credit_item.dart';

/// Card displaying customer credit details.
class CustomerCreditCard extends ConsumerWidget {
  const CustomerCreditCard({
    super.key,
    required this.customer,
    required this.credits,
    this.onHistoryTap,
    this.onPaymentTap,
  });

  final CustomerSummary customer;
  final List<CustomerCredit> credits;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onPaymentTap;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateTotalCredit(List<CustomerCredit> credits) {
    return credits.fold(0, (sum, credit) => sum + credit.remainingAmount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalCredit = _calculateTotalCredit(credits);

    // Ne pas afficher si aucun crédit réel avec montant restant > 0
    if (totalCredit <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: CustomerCreditHeader(
              customer: customer,
              totalCredit: totalCredit,
              formatCurrency: CurrencyFormatter.formatFCFA,
            ),
          ),
          // Credits list
          if (credits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ventes en crédit (${credits.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...credits.map((credit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomerCreditItem(
                        credit: credit,
                        formatCurrency: CurrencyFormatter.formatFCFA,
                        formatDate: _formatDate,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Aucun crédit détaillé',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: CreditActionButtons(
              creditsCount: credits.length,
              onHistoryTap: onHistoryTap,
              onPaymentTap: onPaymentTap,
            ),
          ),
        ],
      ),
    );
  }
}

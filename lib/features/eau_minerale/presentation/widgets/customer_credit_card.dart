import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart' show CustomerSummary;
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

  String _formatCurrency(int amount) {
    final amountStr = amount.toString();
    if (amountStr.length <= 3) {
      return amountStr;
    }
    
    final buffer = StringBuffer();
    final reversed = amountStr.split('').reversed.join();
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(reversed[i]);
    }
    
    return buffer.toString().split('').reversed.join();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int get totalCredit => credits.fold(0, (sum, credit) => sum + credit.remainingAmount);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalCredit = this.totalCredit;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerCreditHeader(
            customer: customer,
            totalCredit: totalCredit,
            formatCurrency: _formatCurrency,
          ),
          const SizedBox(height: 16),
          ...credits.map((credit) {
            return CustomerCreditItem(
              credit: credit,
              formatCurrency: _formatCurrency,
              formatDate: _formatDate,
            );
          }),
          const SizedBox(height: 12),
          // Action buttons
          CreditActionButtons(
            creditsCount: credits.length,
            onHistoryTap: onHistoryTap,
            onPaymentTap: onPaymentTap,
          ),
        ],
      ),
    );
  }
}



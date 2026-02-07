import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';

/// Widget to display the payment amount in a consistent format.
class PaymentAmountDisplay extends StatelessWidget {
  const PaymentAmountDisplay({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return ElyfCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: 20,
      backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
      borderColor: colors.outline.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Montant à Payer',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(amount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wallet_rounded, color: colors.primary, size: 24),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Card displaying profit analysis for a single product.
class ProductProfitCard extends StatelessWidget {
  const ProductProfitCard({
    super.key,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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

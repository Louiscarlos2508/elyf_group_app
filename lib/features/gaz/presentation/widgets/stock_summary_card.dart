import 'package:flutter/material.dart';

import '../../domain/entities/cylinder.dart';

/// Carte récapitulative du stock de bouteilles.
class StockSummaryCard extends StatelessWidget {
  const StockSummaryCard({super.key, required this.cylinders});

  final List<Cylinder> cylinders;

  Color _getStockColor(int stock) {
    if (stock <= 5) return Colors.red;
    if (stock <= 15) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < cylinders.length; i++) ...[
            _CylinderStockRow(
              cylinder: cylinders[i],
              stockColor: _getStockColor(cylinders[i].stock),
            ),
            if (i < cylinders.length - 1)
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }
}

class _CylinderStockRow extends StatelessWidget {
  const _CylinderStockRow({
    required this.cylinder,
    required this.stockColor,
  });

  final Cylinder cylinder;
  final Color stockColor;

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) +
        ' F';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cylinder.type.label} (${cylinder.weight} kg)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Achat: ${_formatCurrency(cylinder.buyPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Vente: ${_formatCurrency(cylinder.sellPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: stockColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cylinder.stock <= 5
                      ? Icons.warning_amber
                      : Icons.inventory_2,
                  size: 18,
                  color: stockColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${cylinder.stock}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stockColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

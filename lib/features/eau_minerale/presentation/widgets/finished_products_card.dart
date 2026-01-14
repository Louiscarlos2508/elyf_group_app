import 'package:flutter/material.dart';

import '../../domain/entities/stock_item.dart';

/// Card displaying finished products stock summary.
class FinishedProductsCard extends StatelessWidget {
  const FinishedProductsCard({super.key, required this.items});

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter finished goods
    final finishedGoods = items
        .where((item) => item.type == StockType.finishedGoods)
        .toList();

    // Find pack item
    StockItem pack;
    if (finishedGoods.isEmpty) {
      pack = StockItem(
        id: 'pack',
        name: 'Pack',
        quantity: 0,
        unit: 'unité',
        type: StockType.finishedGoods,
        updatedAt: DateTime.now(),
      );
    } else {
      pack = finishedGoods.firstWhere(
        (item) =>
            item.name.toLowerCase().contains('pack') ||
            item.name.toLowerCase().contains('sachet'),
        orElse: () => finishedGoods.first,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Produits Finis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProductItem(
            context,
            'Pack',
            'Ajouté par production • Déduit par ventes',
            pack.quantity,
            pack.unit,
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    String name,
    String description,
    double quantity,
    String unit,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${quantity.toStringAsFixed(0)} $unit',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

import '../../domain/entities/stock_item.dart';
import '../../domain/pack_constants.dart';

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

    // Display all finished goods found in stock items
    final displayedGoods = finishedGoods.isNotEmpty 
        ? finishedGoods 
        : [
            StockItem(
              id: packStockItemId,
              enterpriseId: 'default',
              name: packName,
              quantity: 0,
              unit: packUnit,
              type: StockType.finishedGoods,
              updatedAt: DateTime.now(),
            )
          ];

    return ElyfCard(
      isGlass: true,
      borderColor: Colors.green.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
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
          const SizedBox(height: 24),
          ...displayedGoods.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildProductItem(
              context,
              item.name,
              item.id == packStockItemId 
                  ? 'Production terminée • Prêt pour la vente'
                  : 'Produit du catalogue',
              item.quantity,
              item.unit,
              icon: item.name.toLowerCase().contains(packName.toLowerCase()) ? Icons.local_drink_rounded : Icons.inventory_2_outlined,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    String name,
    String description,
    double quantity,
    String unit, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
        ],
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

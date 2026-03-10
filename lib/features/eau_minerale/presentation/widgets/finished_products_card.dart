import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_item.dart';

/// Card sur le tableau de bord affichant le stock des produits finis.
class FinishedProductsCard extends StatelessWidget {
  const FinishedProductsCard({
    super.key,
    required this.items,
    this.products,
  });

  final List<StockItem> items;
  final List<Product>? products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Récupérer les produits finis du catalogue
    final finishedGoodProducts = products?.where((p) => p.isFinishedGood).toList() ?? [];

    if (finishedGoodProducts.isEmpty && items.where((i) => i.type == StockType.finishedGoods).isEmpty) {
      return const SizedBox.shrink();
    }

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
          
          // Afficher chaque produit fini du catalogue
          ...finishedGoodProducts.map((product) {
            final stockItem = items.cast<StockItem?>().firstWhere(
              (i) => i?.id == product.id,
              orElse: () => null,
            );
            
            final quantity = stockItem?.quantity ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildProductItem(
                context,
                product.name,
                product.description ?? 'Stock disponible pour la vente',
                quantity,
                product.unit,
                icon: Icons.local_drink_rounded,
              ),
            );
          }),

          // Optionnel: Articles hors catalogue
          ...() {
            final catalogIds = finishedGoodProducts.map((p) => p.id).toSet();
            final legacyItems = items.where((i) => 
               i.type == StockType.finishedGoods && !catalogIds.contains(i.id)
            ).toList();
            
            if (legacyItems.isEmpty) return <Widget>[];

            return [
              const Divider(height: 32),
              ...legacyItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildProductItem(
                  context,
                  item.name,
                  'Article hors catalogue',
                  item.quantity,
                  item.unit,
                  icon: Icons.help_outline_rounded,
                ),
              )),
            ];
          }(),
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


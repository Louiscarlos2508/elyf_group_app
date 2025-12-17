import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';

/// Section displaying low stock products.
class DashboardLowStockList extends StatelessWidget {
  const DashboardLowStockList({
    super.key,
    required this.products,
    this.onProductTap,
  });

  final List<Product> products;
  final void Function(Product)? onProductTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tous les produits ont un stock suffisant',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  '${products.length} produit(s) en stock faible',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: Text(
                    '${product.stock}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: product.category != null
                    ? Text(product.category!)
                    : null,
                trailing: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.orange,
                ),
                onTap: () => onProductTap?.call(product),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../domain/entities/product.dart';

/// Section displaying low stock products.
class DashboardLowStockList extends StatelessWidget {
  final void Function(Product)? onProductTap;
  final void Function(Product)? onRestockTap;

  const DashboardLowStockList({
    super.key,
    required this.products,
    this.onProductTap,
    this.onRestockTap,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (products.isEmpty) {
      return ElyfCard(
        isGlass: true,
        backgroundColor: AppColors.success.withValues(alpha: 0.08),
        borderColor: AppColors.success.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tous les produits ont un stock suffisant',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ElyfCard(
      isGlass: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: const Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 12),
                Text(
                  '${products.length} produit(s) en stock faible',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
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
                  backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  child: Text(
                    '${product.stock}',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
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
                subtitle: product.categoryId != null
                    ? Text(product.categoryId!)
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  color: const Color(0xFFF59E0B),
                  tooltip: 'Réapprovisionner',
                  onPressed: () => onRestockTap?.call(product),
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

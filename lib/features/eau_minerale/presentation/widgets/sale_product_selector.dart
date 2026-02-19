import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/pack_constants.dart';


class SaleProductSelector extends ConsumerWidget {
  const SaleProductSelector({
    super.key,
    required this.selectedProduct,
    required this.onProductSelected,
  });

  final Product? selectedProduct;
  final ValueChanged<Product> onProductSelected;

  Future<void> _selectProduct(BuildContext context, WidgetRef ref) async {
    List<Product> list;
    int packStock = 0;
    try {
      final products = await ref.read(productsProvider.future);
      list = products
          .where((p) => p.isFinishedGood)
          .toList();
      if (list.isEmpty) {
        if (!context.mounted) return;
        NotificationService.showInfo(context, 'Aucun produit disponible');
        return;
      }
      // Stock will be fetched per item in the view
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(context, 'Impossible de charger: $e');
      return;
    }

    if (!context.mounted) return;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final selected = await showDialog<Product>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: ElyfCard(
            isGlass: true,
            padding: EdgeInsets.zero,
            borderRadius: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: colors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir un produit',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Produits finis disponibles',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = list[index];
                      return Consumer(builder: (context, ref, child) {
                        final stockAsync = ref.watch(productStockQuantityProvider(product.name));
                        final stock = stockAsync.value ?? 0;
                        final isOutOfStock = stock <= 0 && !stockAsync.isLoading;
                        
                        return ElyfCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 20,
                          backgroundColor: isOutOfStock 
                              ? colors.errorContainer.withValues(alpha: 0.1)
                              : colors.surfaceContainerLow.withValues(alpha: 0.5),
                          borderColor: isOutOfStock 
                              ? colors.error.withValues(alpha: 0.2)
                              : colors.outline.withValues(alpha: 0.1),
                          onTap: isOutOfStock ? null : () => Navigator.of(context).pop(product),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? colors.errorContainer
                                        : colors.primaryContainer.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isOutOfStock ? Icons.production_quantity_limits_rounded : Icons.local_drink_rounded,
                                    color: isOutOfStock ? colors.error : colors.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${CurrencyFormatter.formatFCFA(product.unitPrice)} / ${product.unit}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOutOfStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: colors.error,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'RUPTURE',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colors.onError,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      stockAsync.when(
                                        data: (s) => Text(
                                          '$s',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.primary,
                                          ),
                                        ),
                                        loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                        error: (_, __) => const Icon(Icons.error_outline, size: 16),
                                      ),
                                      Text(
                                        'en stock',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null) onProductSelected(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final productStockAsync = selectedProduct != null 
        ? ref.watch(productStockQuantityProvider(selectedProduct!.name))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _selectProduct(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedProduct != null 
                    ? colors.primary.withValues(alpha: 0.3)
                    : colors.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(16),
              color: selectedProduct != null 
                  ? colors.primary.withValues(alpha: 0.02)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (selectedProduct != null ? colors.primary : colors.surfaceContainerHighest)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: selectedProduct != null ? colors.primary : colors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedProduct?.name ?? 'Sélectionner un produit',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: selectedProduct != null ? FontWeight.bold : FontWeight.normal,
                          color: selectedProduct != null ? colors.onSurface : colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedProduct != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${CurrencyFormatter.formatFCFA(selectedProduct!.unitPrice)} / ${selectedProduct!.unit}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (productStockAsync != null)
                              productStockAsync.when(
                                data: (stock) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (stock > 0 ? colors.primary : colors.error).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Stock: $stock',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: stock > 0 ? colors.primary : colors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1)),
                                error: (_, __) => const Icon(Icons.error_outline, size: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
        if (selectedProduct == null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(
              'Champ requis',
              style: theme.textTheme.labelSmall?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}

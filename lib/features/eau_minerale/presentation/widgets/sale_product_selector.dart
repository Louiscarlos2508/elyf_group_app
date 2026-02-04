import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/pack_constants.dart';

/// Sélecteur Pack pour les ventes. Stock = [packStockQuantityProvider],
/// même source que Stock / Dashboard.
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
          .where((p) =>
              p.id == packProductId ||
              (p.isFinishedGood &&
                  p.name.toLowerCase().contains(packName.toLowerCase())))
          .toList();
      if (list.isEmpty) {
        if (!context.mounted) return;
        NotificationService.showInfo(context, 'Aucun produit disponible');
        return;
      }
      packStock = await ref.read(packStockQuantityProvider.future);
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(
        context,
        'Impossible de charger: $e',
      );
      return;
    }

    if (!context.mounted) return;
    final theme = Theme.of(context);

    final selected = await showDialog<Product>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Sélectionner le produit',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = list[index];
                    final isOutOfStock = packStock <= 0;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(product),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isOutOfStock
                                  ? theme.colorScheme.error.withValues(alpha: 0.3)
                                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isOutOfStock
                                ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? theme.colorScheme.errorContainer
                                      : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isOutOfStock ? Icons.production_quantity_limits : Icons.local_drink,
                                  color: isOutOfStock
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.secondary,
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
                                        fontWeight: FontWeight.w600,
                                        decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${product.unitPrice} CFA / ${product.unit}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isOutOfStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'RUPTURE',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onError,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      '$packStock',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'en stock',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) onProductSelected(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packStockAsync = ref.watch(packStockQuantityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _selectProduct(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produit',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedProduct?.name ?? 'Sélectionner un produit',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: selectedProduct != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: selectedProduct != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedProduct != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${selectedProduct!.unitPrice} CFA/${selectedProduct!.unit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            packStockAsync.when(
                              data: (stock) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    size: 14,
                                    color: stock > 0
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Stock: $stock $packUnit',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: stock > 0
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              loading: () => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Stock…',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              error: (_, __) => Text(
                                'Stock indisponible',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (selectedProduct == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              'Requis',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

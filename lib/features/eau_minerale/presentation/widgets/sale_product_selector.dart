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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sélectionner le produit',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: list.map((product) {
                    final isOutOfStock = packStock <= 0;
                    return ListTile(
                      enabled: true,
                      leading: Icon(
                        Icons.inventory_2_outlined,
                        color: isOutOfStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${product.unitPrice} CFA/${product.unit}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 14,
                                color: isOutOfStock
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: $packStock ${product.unit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOutOfStock
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isOutOfStock
                          ? Chip(
                              label: const Text('Rupture'),
                              backgroundColor:
                                  theme.colorScheme.errorContainer,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(product),
                    );
                  }).toList(),
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

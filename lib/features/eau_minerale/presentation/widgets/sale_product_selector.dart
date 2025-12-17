import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/product.dart';

/// Widget for selecting a product in the sale form.
class SaleProductSelector extends ConsumerWidget {
  const SaleProductSelector({
    super.key,
    required this.selectedProduct,
    required this.onProductSelected,
  });

  final Product? selectedProduct;
  final ValueChanged<Product> onProductSelected;

  Future<void> _selectProduct(BuildContext context, WidgetRef ref) async {
    final products = await ref.read(productsProvider.future);
    final finishedGoods = products.where((p) => p.isFinishedGood).toList();

    if (finishedGoods.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit disponible')),
      );
      return;
    }

    final stockRepository = ref.read(stockRepositoryProvider);
    
    // Charger les stocks avant d'afficher le dialogue
    final stockFutures = finishedGoods.map((p) => 
      stockRepository.getStock(p.id).then((s) => MapEntry(p.id, s))
    );
    final stocksMap = await Future.wait(stockFutures).then((entries) => Map.fromEntries(entries));

    if (!context.mounted) return;
    final theme = Theme.of(context);
    
    final selected = await showDialog<Product>(
      context: context,
      builder: (dialogContext) => Dialog(
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: finishedGoods.map((product) {
                    final availableStock = stocksMap[product.id] ?? 0;
                    final isOutOfStock = availableStock <= 0;
                    
                    return ListTile(
                      enabled: !isOutOfStock,
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
                                'Stock: $availableStock ${product.unit}',
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
                              backgroundColor: theme.colorScheme.errorContainer,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      onTap: isOutOfStock
                          ? null
                          : () => Navigator.of(dialogContext).pop(product),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      onProductSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stockRepository = ref.watch(stockRepositoryProvider);
    
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 300;
                            
                            if (isWide) {
                              return Row(
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
                                  FutureBuilder<int>(
                                    future: stockRepository.getStock(selectedProduct!.id),
                                    builder: (context, snapshot) {
                                      final stock = snapshot.data ?? 0;
                                      return Row(
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
                                            'Stock: $stock',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: stock > 0
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selectedProduct!.unitPrice} CFA/${selectedProduct!.unit}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: stockRepository.getStock(selectedProduct!.id),
                                    builder: (context, snapshot) {
                                      final stock = snapshot.data ?? 0;
                                      return Row(
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
                                            'Stock: $stock',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: stock > 0
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              );
                            }
                          },
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


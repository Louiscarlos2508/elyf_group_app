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

    if (!context.mounted) return;
    final selected = await showDialog<Product>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sélectionner le produit'),
        children: finishedGoods.map((product) {
          return ListTile(
            title: Text(product.name),
            subtitle: Text('${product.unitPrice} CFA/${product.unit}'),
            onTap: () => Navigator.of(context).pop(product),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      onProductSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                      ),
                      if (selectedProduct != null)
                        Text(
                          '${selectedProduct!.unitPrice} CFA/${selectedProduct!.unit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
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


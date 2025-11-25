import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/permissions/eau_minerale_permissions.dart';
import 'centralized_permission_guard.dart';
import 'product_catalog_tabs.dart';
import 'product_form_dialog.dart';
import 'product_list_item.dart';

/// Product catalog management card with tabs and product list.
class ProductCatalogCard extends ConsumerStatefulWidget {
  const ProductCatalogCard({super.key});

  @override
  ConsumerState<ProductCatalogCard> createState() =>
      _ProductCatalogCardState();
}

class _ProductCatalogCardState extends ConsumerState<ProductCatalogCard> {
  ProductType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Catalogue de Produits',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gérez vos matières premières et produits finis',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                EauMineralePermissionGuard(
                  permission: EauMineralePermissions.manageProducts,
                  child: IntrinsicWidth(
                    child: FilledButton.icon(
                      onPressed: () => _showAddProductDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProductCatalogTabs(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            ),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) {
                final filtered = _selectedFilter == null
                    ? products
                    : products.where((p) => p.type == _selectedFilter).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucun produit'),
                    ),
                  );
                }
                return Column(
                  children: filtered.map<Widget>((product) {
                    return ProductListItem(
                      product: product,
                      onEdit: () => _showEditProductDialog(context, product),
                      onDelete: () => _showDeleteConfirm(context, product),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erreur: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProductFormDialog(),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  void _showDeleteConfirm(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(productRepositoryProvider).deleteProduct(product.id);
              ref.invalidate(productsProvider);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

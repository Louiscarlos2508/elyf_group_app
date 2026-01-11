import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/product_filter_service.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/restock_dialog.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products, String query) {
    return ProductFilterService.filterProducts(
      products: products,
      query: query,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Produits',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                BoutiquePermissionGuard(
                  permission: BoutiquePermissions.createProduct,
                  child: IntrinsicWidth(
                    child: FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ProductFormDialog(),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau Produit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: productsAsync.when(
            data: (products) {
              final filteredProducts = _filterProducts(products, _searchQuery);
              if (filteredProducts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun produit enregistré'
                              : 'Aucun résultat pour "$_searchQuery"',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width > 1200
                      ? 6
                      : width > 900
                          ? 5
                          : width > 600
                              ? 4
                              : width > 400
                                  ? 3
                                  : 2;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index];
                    return ProductTile(
                      product: product,
                      showRestockButton: true,
                      onTap: () {
                        // Vérifier la permission d'édition
                        final adapter = ref.read(boutiquePermissionAdapterProvider);
                        adapter.hasPermission(BoutiquePermissions.editProduct.id).then((hasPermission) {
                          if (hasPermission && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => ProductFormDialog(product: product),
                            );
                          } else if (context.mounted) {
                            NotificationService.showError(
                              context,
                              'Vous n\'avez pas la permission de modifier les produits.',
                            );
                          }
                        });
                      },
                      onRestock: () {
                        // Vérifier la permission d'édition du stock
                        final adapter = ref.read(boutiquePermissionAdapterProvider);
                        adapter.hasPermission(BoutiquePermissions.editStock.id).then((hasPermission) {
                          if (hasPermission && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => RestockDialog(product: product),
                            );
                          } else if (context.mounted) {
                            NotificationService.showError(
                              context,
                              'Vous n\'avez pas la permission de modifier le stock.',
                            );
                          }
                        });
                      },
                    );
                  },
                  childCount: filteredProducts.length,
                ),
                );
              },
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Erreur de chargement',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


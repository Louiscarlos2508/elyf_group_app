import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/product_filter_service.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/restock_dialog.dart';
import '../../widgets/boutique_header.dart';
import '../../widgets/boutique_search_bar.dart';

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
    final productsAsync = ref.watch(productsProvider);

    return CustomScrollView(
      slivers: [
        BoutiqueHeader(
          title: "CATALOGUE",
          subtitle: "Produits & Stocks",
          gradientColors: [
            const Color(0xFF059669), // Emerald 600
            const Color(0xFF047857), // Emerald 700
          ],
          shadowColor: const Color(0xFF059669),
          additionalActions: [
            BoutiquePermissionGuard(
              permission: BoutiquePermissions.createProduct,
              child: IntrinsicWidth(
                child: Semantics(
                  label: 'Nouveau produit',
                  hint: 'Créer un nouveau produit dans le catalogue',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ProductFormDialog(),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau Produit'),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverToBoxAdapter(
            child: BoutiqueSearchBar(
              controller: _searchController,
              hintText: 'Rechercher un produit...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.lg),
          sliver: productsAsync.when(
            data: (products) {
              final filteredProducts = _filterProducts(products, _searchQuery);
              if (filteredProducts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _searchQuery.isEmpty
                        ? 'Aucun produit enregistré'
                        : 'Aucun résultat',
                    message: _searchQuery.isEmpty
                        ? 'Commencez par ajouter un produit au catalogue'
                        : 'Aucun produit ne correspond à "$_searchQuery"',
                    action: _searchQuery.isEmpty
                        ? Semantics(
                            label: 'Ajouter un produit',
                            button: true,
                            child: FilledButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const ProductFormDialog(),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un produit'),
                            ),
                          )
                        : null,
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filteredProducts[index];
                      return ProductTile(
                        product: product,
                        showRestockButton: true,
                        onTap: () {
                          // Vérifier la permission d'édition
                          final adapter = ref.read(
                            boutiquePermissionAdapterProvider,
                          );
                          adapter
                              .hasPermission(BoutiquePermissions.editProduct.id)
                              .then((hasPermission) {
                                if (hasPermission && context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        ProductFormDialog(product: product),
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
                          final adapter = ref.read(
                            boutiquePermissionAdapterProvider,
                          );
                          adapter
                              .hasPermission(BoutiquePermissions.editStock.id)
                              .then((hasPermission) {
                                if (hasPermission && context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        RestockDialog(product: product),
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
                    }, childCount: filteredProducts.length),
                  );
                },
              );
            },
            loading: () => SliverFillRemaining(
                child: AppShimmers.grid(context, count: 8),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: ErrorDisplayWidget(
                error: error,
                title: 'Erreur de chargement',
                message: 'Impossible de charger les produits.',
                onRetry: () => ref.refresh(productsProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

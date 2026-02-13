import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/domain/services/product_filter_service.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/permission_guard.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/product_form_dialog.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/product_tile.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/purchase_entry_dialog.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/stock_adjustment_dialog.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_search_bar.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/stock_movement_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_category_filter.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/price_history_dialog.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products, String query, String? categoryId, List<Category> categories) {
    var filtered = products;

    if (categoryId != null) {
      filtered = ProductFilterService.filterByCategory(
        products: filtered,
        categoryId: categoryId,
      );
    }

    if (query.isNotEmpty) {
      final categoryNames = {for (var c in categories) c.id: c.name};
      filtered = ProductFilterService.filterProducts(
        products: filtered,
        query: query,
        categoryNames: categoryNames,
      );
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

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
              permission: BoutiquePermissions.viewReports, // Or stock permission?
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StockMovementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Historique des stocks',
              ),
            ),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: categoriesAsync.when(
            data: (categories) => SliverToBoxAdapter(
              child: BoutiqueCategoryFilter(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
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
              final categories = categoriesAsync.value ?? [];
              final filteredProducts = _filterProducts(
                products,
                _searchQuery,
                _selectedCategory,
                categories,
              );
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
                                        PurchaseEntryDialog(initialProduct: product),
                                  );
                                } else if (context.mounted) {
                                  NotificationService.showError(
                                    context,
                                    'Vous n\'avez pas la permission de modifier le stock.',
                                  );
                                }
                              });
                        },
                        onAdjust: () {
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
                                        StockAdjustmentDialog(product: product),
                                  );
                                } else if (context.mounted) {
                                  NotificationService.showError(
                                    context,
                                    'Vous n\'avez pas la permission de modifier le stock.',
                                  );
                                }
                              });
                        },
                        onPriceHistory: () {
                          showDialog(
                            context: context,
                            builder: (_) => PriceHistoryDialog(product: product),
                          );
                        },
                        onDuplicate: () {
                          // Check create permission (duplication is essentially creation)
                          final adapter = ref.read(boutiquePermissionAdapterProvider);
                          adapter.hasPermission(BoutiquePermissions.createProduct.id)
                              .then((hasPermission) {
                                if (hasPermission && context.mounted) {
                                  // Create a copy for duplication
                                  final duplicate = product.copyWith(
                                    id: '', // New ID will be generated
                                    name: '${product.name} (Copie)',
                                    stock: 0, // Reset stock
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  
                                  showDialog(
                                    context: context,
                                    builder: (_) => ProductFormDialog(product: duplicate),
                                  );
                                } else if (context.mounted) {
                                  NotificationService.showError(
                                    context,
                                    'Vous n\'avez pas la permission de créer des produits.',
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

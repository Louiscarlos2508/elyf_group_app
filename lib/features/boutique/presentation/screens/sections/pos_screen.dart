import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/closing.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/cart_item.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/cart_summary.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/checkout_dialog.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/permission_guard.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/product_tile.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/barcode_scanner_widget.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_search_bar.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_category_filter.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart';
import 'dart:convert';
import '../../widgets/boutique_header.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';
import 'package:elyf_groupe_app/features/boutique/domain/services/product_filter_service.dart';
import '../../widgets/opening_session_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<CartItem> _cartItems = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  double _discountPercentage = 0.0;
  bool _hasHeldCart = false;

  @override
  void initState() {
    super.initState();
    _checkHeldCart();
  }

  Future<void> _checkHeldCart() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _hasHeldCart = prefs.containsKey('boutique_held_cart');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    // Session Guard
    final activeSession = ref.read(activeSessionProvider).value;
    if (activeSession == null || activeSession.status != ClosingStatus.open) {
      NotificationService.showWarning(
        context,
        'Caisse fermée. Veuillez ouvrir la caisse avant de vendre.',
      );
      return;
    }

    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existingIndex >= 0) {
        final existing = _cartItems[existingIndex];
        if (existing.quantity < product.stock) {
          _cartItems[existingIndex] = existing.copyWith(
            quantity: existing.quantity + 1,
          );
        } else {
          NotificationService.showInfo(context, 'Stock insuffisant');
        }
      } else {
        if (product.stock > 0) {
          _cartItems.add(CartItem(product: product, quantity: 1));
        } else {
          NotificationService.showInfo(context, 'Produit en rupture de stock');
        }
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(index);
      return;
    }
    setState(() {
      final item = _cartItems[index];
      if (quantity <= item.product.stock) {
        _cartItems[index] = item.copyWith(quantity: quantity);
      } else {
        NotificationService.showInfo(context, 'Stock insuffisant');
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _selectedCategory = null;
    });
  }

  void _holdCart() async {
    if (_cartItems.isEmpty) return;
    
    final prefs = ref.read(sharedPreferencesProvider);
    final cartJson = jsonEncode(_cartItems.map((item) => {
      'productId': item.product.id,
      'quantity': item.quantity,
    }).toList());
    
    await prefs.setString('boutique_held_cart', cartJson);
    setState(() {
      _cartItems.clear();
      _hasHeldCart = true;
    });
    
    if (mounted) {
      NotificationService.showSuccess(context, 'Panier mis en attente');
    }
  }

  void _resumeCart() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cartJson = prefs.getString('boutique_held_cart');
    if (cartJson == null) return;
    
    final productsAsync = ref.read(productsProvider);
    productsAsync.whenData((products) {
      final List<dynamic> decoded = jsonDecode(cartJson);
      setState(() {
        _cartItems.clear();
        for (final itemData in decoded) {
          try {
            final product = products.firstWhere((p) => p.id == itemData['productId']);
            _cartItems.add(CartItem(product: product, quantity: itemData['quantity'] as int));
          } catch (e) {
            // Product not found, skip
          }
        }
        prefs.remove('boutique_held_cart');
        _hasHeldCart = false;
      });
      NotificationService.showSuccess(context, 'Panier repris');
    });
  }

  void _applyDiscount() {
    if (_cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appliquer une remise (%)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0, 5, 10, 15, 20].map((p) => ListTile(
            title: Text('$p %'),
            onTap: () {
              setState(() => _discountPercentage = p.toDouble());
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showCheckout(BuildContext context) async {
    // Session Guard
    final activeSession = ref.read(activeSessionProvider).value;
    if (activeSession == null || activeSession.status != ClosingStatus.open) {
      NotificationService.showWarning(
        context,
        'Caisse fermée. Veuillez ouvrir la caisse avant de procéder au paiement.',
      );
      return;
    }

    if (_cartItems.isEmpty) {
      NotificationService.showInfo(context, 'Le panier est vide');
      return;
    }

    // V\u00e9rifier les permissions avant d'ouvrir le checkout
    final adapter = ref.read(boutiquePermissionAdapterProvider);
    final hasUsePos = await adapter.hasPermission(
      BoutiquePermissions.usePos.id,
    );
    final hasCreateSale = await adapter.hasPermission(
      BoutiquePermissions.createSale.id,
    );

    if (!hasUsePos && !hasCreateSale) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Vous n\'avez pas la permission d\'utiliser la caisse ou de cr\u00e9er une vente.',
        );
      }
      return;
    }

    final total = _cartTotal;
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => CheckoutDialog(
          cartItems: _cartItems,
          total: total,
          onSuccess: () {
            _clearCart();
          },
        ),
      );
    }
  }

  void _showCartBottomSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (scrollContext, scrollController) => CartSummary(
          cartItems: _cartItems,
          onRemove: _removeFromCart,
          onUpdateQuantity: _updateQuantity,
          onClear: _clearCart,
          onHold: _holdCart,
          onDiscount: _applyDiscount,
          onCheckout: () {
            Navigator.of(scrollContext).pop();
            _showCheckout(parentContext);
          },
        ),
      ),
    );
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

  int get _cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  int get _cartTotal {
    final rawTotal = ref.read(storeControllerProvider).calculateCartTotal(_cartItems);
    if (_discountPercentage > 0) {
      return (rawTotal * (1 - _discountPercentage / 100)).round();
    }
    return rawTotal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(activeProductsProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isSessionOpen = activeSessionAsync.value?.status == ClosingStatus.open;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        return Stack(
          children: [
            Column(
              children: [
                if (!isSessionOpen)
                  Container(
                    width: double.infinity,
                    color: Colors.orange[800],
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'CAISSE FERMÉE. Veuillez ouvrir une session sur le Dashboard pour vendre.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const OpeningSessionDialog(),
                            );
                          },
                          child: const Text(
                            'OUVRIR',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: isWide ? 2 : 1,
                        child: CustomScrollView(
                          slivers: [
                            BoutiqueHeader(
                              title: "POINT DE VENTE",
                              subtitle: "Caisse & Panier",
                              gradientColors: const [
                                Color(0xFF2563EB), // Blue 600
                                Color(0xFF1D4ED8), // Blue 700
                              ],
                              shadowColor: const Color(0xFF2563EB),
                              additionalActions: [
                                if (_hasHeldCart)
                                  IconButton(
                                    icon: const Icon(Icons.shopping_basket_outlined, color: Colors.white),
                                    onPressed: _resumeCart,
                                    tooltip: 'Reprendre le panier en attente',
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
                                  onScanPressed: () async {
                                    final scannedBarcode =
                                        await Navigator.of(context).push<String>(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BarcodeScannerWidget(
                                          onBarcodeDetected: (barcode) {
                                            Navigator.of(context).pop(barcode);
                                          },
                                          onError: (error) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (context.mounted) {
                                                NotificationService.showError(
                                                  context,
                                                  'Erreur de scan: $error',
                                                );
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    );

                                    if (scannedBarcode != null && mounted) {
                                      final productsAsync =
                                          ref.read(productsProvider);
                                      productsAsync.whenData((products) {
                                        try {
                                          final product = products.firstWhere(
                                            (p) => p.barcode == scannedBarcode,
                                          );
                                          _addToCart(product);
                                          NotificationService.showSuccess(
                                            context,
                                            '${product.name} ajouté au panier',
                                          );
                                        } catch (e) {
                                          NotificationService.showWarning(
                                            context,
                                            'Produit avec code-barres $scannedBarcode non trouvé',
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            categoriesAsync.when(
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
                            productsAsync.when(
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
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _searchQuery.isEmpty
                                                ? Icons.inventory_2_outlined
                                                : Icons.search_off,
                                            size: 64,
                                            color: theme
                                                .colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchQuery.isEmpty
                                                ? 'Aucun produit disponible'
                                                : 'Aucun résultat pour "$_searchQuery"',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return SliverPadding(
                                  padding: const EdgeInsets.all(16),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isWide ? (constraints.maxWidth > 1000 ? 5 : 3) : 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final product = filteredProducts[index];
                                        return ProductTile(
                                          product: product,
                                          isEnabled: isSessionOpen,
                                          onTap: () => _addToCart(product),
                                        );
                                      },
                                      childCount: filteredProducts.length,
                                    ),
                                  ),
                                );
                              },
                              loading: () => SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: AppShimmers.grid(context, count: 8),
                                ),
                              ),
                              error: (_, __) => SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Erreur de chargement',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) ...[
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 400,
                          child: CartSummary(
                            cartItems: _cartItems,
                            onRemove: _removeFromCart,
                            onUpdateQuantity: _updateQuantity,
                            onClear: _clearCart,
                            onHold: _holdCart,
                            onDiscount: _applyDiscount,
                            onCheckout: () => _showCheckout(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!isWide && _cartItems.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: BoutiquePermissionGuardAny(
                  permissions: const [
                    BoutiquePermissions.usePos,
                    BoutiquePermissions.createSale,
                  ],
                  fallback: const SizedBox.shrink(),
                  child: FloatingActionButton.extended(
                    onPressed: () => _showCartBottomSheet(context),
                    icon: Badge(
                      label: Text('$_cartItemCount'),
                      child: const Icon(Icons.shopping_cart),
                    ),
                    label: Text(CurrencyFormatter.formatFCFA(_cartTotal)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

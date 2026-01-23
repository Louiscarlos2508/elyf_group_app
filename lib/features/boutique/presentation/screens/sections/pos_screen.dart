import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/cart_summary.dart';
import '../../widgets/checkout_dialog.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/barcode_scanner_widget.dart';
import 'package:elyf_groupe_app/shared.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<CartItem> _cartItems = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
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
    });
  }

  void _showCheckout(BuildContext context) async {
    if (_cartItems.isEmpty) {
      NotificationService.showInfo(context, 'Le panier est vide');
      return;
    }

    // Vérifier les permissions avant d'ouvrir le checkout
    final adapter = ref.read(boutiquePermissionAdapterProvider);
    final hasUsePos = await adapter.hasPermission(
      BoutiquePermissions.usePos.id,
    );
    final hasCreateSale = await adapter.hasPermission(
      BoutiquePermissions.createSale.id,
    );

    if (!hasUsePos && !hasCreateSale) {
      NotificationService.showError(
        context,
        'Vous n\'avez pas la permission d\'utiliser la caisse ou de créer une vente.',
      );
      return;
    }

    final total = ref
        .read(storeControllerProvider)
        .calculateCartTotal(_cartItems);
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

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CartSummary(
          cartItems: _cartItems,
          onRemove: _removeFromCart,
          onUpdateQuantity: _updateQuantity,
          onClear: _clearCart,
          onCheckout: () {
            Navigator.of(context).pop();
            _showCheckout(context);
          },
        ),
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          (product.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (product.barcode?.contains(query) ?? false);
    }).toList();
  }

  int get _cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  int get _cartTotal {
    return ref.read(storeControllerProvider).calculateCartTotal(_cartItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: isWide ? 2 : 1,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
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
                                  filled: true,
                                  fillColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () async {
                                // ✅ TODO résolu: Implement barcode scanning
                                final scannedBarcode = await Navigator.of(context).push<String>(
                                  MaterialPageRoute(
                                    builder: (context) => BarcodeScannerWidget(
                                      onBarcodeDetected: (barcode) {
                                        Navigator.of(context).pop(barcode);
                                      },
                                      onError: (error) {
                                        NotificationService.showError(
                                          context,
                                          'Erreur de scan: $error',
                                        );
                                      },
                                    ),
                                  ),
                                );

                                if (scannedBarcode != null && mounted) {
                                  // Rechercher le produit par code-barres
                                  final productsAsync = ref.read(productsProvider);
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
                              tooltip: 'Scanner un code-barres',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: productsAsync.when(
                          data: (products) {
                            final filteredProducts = _filterProducts(
                              products,
                              _searchQuery,
                            );
                            if (filteredProducts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isEmpty
                                          ? Icons.inventory_2_outlined
                                          : Icons.search_off,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'Aucun produit disponible'
                                          : 'Aucun résultat pour "$_searchQuery"',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide ? 4 : 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ProductTile(
                                  product: product,
                                  onTap: () => _addToCart(product),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => Center(
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
                                  style: theme.textTheme.bodyLarge?.copyWith(
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
                      onCheckout: () => _showCheckout(context),
                    ),
                  ),
                ],
              ],
            ),
            if (!isWide && _cartItems.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: BoutiquePermissionGuardAny(
                  permissions: [
                    BoutiquePermissions.usePos,
                    BoutiquePermissions.createSale,
                  ],
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
                  fallback: const SizedBox.shrink(),
                ),
              ),
          ],
        );
      },
    );
  }
}

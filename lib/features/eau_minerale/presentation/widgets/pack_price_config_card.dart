import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/pack_constants.dart';

/// Widget pour configurer le prix du pack dans les paramètres.
class PackPriceConfigCard extends ConsumerStatefulWidget {
  const PackPriceConfigCard({super.key});

  @override
  ConsumerState<PackPriceConfigCard> createState() =>
      _PackPriceConfigCardState();
}

class _PackPriceConfigCardState extends ConsumerState<PackPriceConfigCard> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  Product? _packProduct;
  int _packStockQuantity = -1;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPackProduct();
  }

  Future<void> _loadPackProduct() async {
    if (!mounted) return;
    _loadError = null;
    final productController = ref.read(productControllerProvider);
    final stockCtrl = ref.read(stockControllerProvider);

    List<Object?> results;
    try {
      results = await Future.wait<Object?>([
        productController.ensurePackProduct(),
        stockCtrl.ensurePackStockItem(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
      return;
    }

    if (!mounted) return;
    final pack = results[0] is Product ? results[0] as Product : null;
    if (pack == null) {
      setState(() => _loadError = 'Pack introuvable');
      return;
    }
    final stockQty = results[1] is StockItem
        ? (results[1] as StockItem).quantity.toInt()
        : -1;

    setState(() {
      _packProduct = pack;
      _priceController.text = pack.unitPrice.toString();
      _packStockQuantity = stockQty;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _savePrice() async {
    if (!_formKey.currentState!.validate() || _packProduct == null) return;

    final newPrice = int.tryParse(_priceController.text);
    if (newPrice == null || newPrice <= 0) {
      if (!mounted) return;
      NotificationService.showWarning(context, 'Prix invalide');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedProduct = Product(
        id: _packProduct!.id,
        name: _packProduct!.name,
        type: _packProduct!.type,
        unitPrice: newPrice,
        unit: _packProduct!.unit,
        description: _packProduct!.description,
      );

      final productController = ref.read(productControllerProvider);
      await productController.updateProduct(updatedProduct);

      // Invalider le provider pour recharger les produits
      ref.invalidate(productsProvider);

      if (!mounted) return;
      NotificationService.showSuccess(context, 'Prix du pack mis à jour');

      setState(() {
        _packProduct = updatedProduct;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pack = _packProduct;

    if (pack == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: _loadError != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: colors.error),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          _loadError = null;
                          _loadPackProduct();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement du pack…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.price_change_outlined,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix du $packName',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Synchronisé avec Stock & Ventes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Prix unitaire (CFA)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        suffixText: 'CFA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        final price = int.tryParse(v);
                        if (price == null || price <= 0) {
                          return 'Prix invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _savePrice,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Mettre à jour'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Stock Info Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ÉTAT DU STOCK',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurfaceVariant,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _packStockQuantity >= 0
                              ? '$_packStockQuantity $packUnit(s) disponibles'
                              : 'Chargement du stock...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

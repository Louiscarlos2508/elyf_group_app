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
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: colors.error,
                      ),
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
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.price_change_outlined,
                          color: colors.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prix du $packName',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Même produit que dans Stock et Ventes',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Prix unitaire (CFA)',
                            prefixIcon: const Icon(Icons.attach_money),
                            suffixText: 'CFA',
                            helperText: 'Prix de vente d\'un pack',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                      const SizedBox(width: 16),
                      Flexible(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _savePrice,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Enregistrer'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Produit: ${pack.name} • Prix: ${pack.unitPrice} CFA/$packUnit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_packStockQuantity >= 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Stock actuel: $_packStockQuantity $packUnit(s) '
                            '(écran Stock)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

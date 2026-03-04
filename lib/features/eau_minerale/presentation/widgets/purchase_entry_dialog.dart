import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/state_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/supplier.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/permission_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';

class PurchaseEntryDialog extends ConsumerStatefulWidget {
  const PurchaseEntryDialog({super.key});

  @override
  ConsumerState<PurchaseEntryDialog> createState() => _PurchaseEntryDialogState();
}

class _PurchaseEntryDialogState extends ConsumerState<PurchaseEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Item entry
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitsPerLotController = TextEditingController(text: '1000');
  bool _useLots = false;
  
  // Purchase state
  final List<PurchaseItem> _items = [];
  Supplier? _selectedSupplier;
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  PurchaseStatus _status = PurchaseStatus.validated;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _unitsPerLotController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_selectedProduct == null) {
      NotificationService.showWarning(context, 'Sélectionnez un produit');
      return;
    }
    final qtyStr = _quantityController.text.trim().replaceAll(',', '.');
    final priceStr = _priceController.text.trim();
    
    final qty = double.tryParse(qtyStr) ?? 0;
    final price = int.tryParse(priceStr) ?? 0;
    final unitsPerLot = int.tryParse(_unitsPerLotController.text) ?? (_selectedProduct?.unitsPerLot ?? 1);

    if (qty <= 0) {
      NotificationService.showWarning(context, 'Quantité requise');
      return;
    }

    // Calculer la quantité finale en unités
    final finalQty = _useLots ? (qty * unitsPerLot).round() : qty.round();
    
    int finalTotalPrice;
    int finalUnitPrice;

    if (priceStr.isNotEmpty) {
      // Prix total saisi manuellement
      finalTotalPrice = int.tryParse(priceStr) ?? 0;
      finalUnitPrice = finalQty > 0 ? (finalTotalPrice / finalQty).round() : 0;
    } else {
      // Utiliser le prix unitaire du catalogue
      finalUnitPrice = _selectedProduct!.unitPrice;
      finalTotalPrice = (finalQty * finalUnitPrice).round();
    }

    setState(() {
      _items.add(PurchaseItem(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        quantity: finalQty,
        unitPrice: finalUnitPrice,
        totalPrice: finalTotalPrice,
        unit: _selectedProduct!.unit,
        metadata: {
          'isInLots': _useLots,
          'unitsPerLot': unitsPerLot,
          'quantitySaisie': qty,
          'prixSaisi': priceStr.isNotEmpty ? int.tryParse(priceStr) : null,
          'isPriceManual': priceStr.isNotEmpty,
        },
      ));
      _selectedProduct = null;
      _quantityController.clear();
      _priceController.clear();
      _useLots = false;
    });
  }

  int get _totalAmount => _items.fold<int>(0, (sum, item) => sum + item.totalPrice);

  Future<void> _submit() async {
    if (_items.isEmpty) {
      NotificationService.showWarning(context, 'Ajoutez au moins un article');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? 'default';
      final paid = int.tryParse(_paidAmountController.text) ?? _totalAmount;

      // Enforce supplier selection for credit purchases
      if (paid < _totalAmount && _selectedSupplier == null) {
        NotificationService.showWarning(
          context,
          'Un fournisseur est obligatoire pour un achat à crédit.',
        );
        setState(() => _isLoading = false);
        return;
      }

      final purchase = Purchase(
        id: '',
        enterpriseId: enterpriseId,
        date: DateTime.now(),
        items: List.from(_items),
        totalAmount: _totalAmount,
        paidAmount: paid,
        supplierId: _selectedSupplier?.id,
        status: _status,
        notes: _notesController.text,
        paymentMethod: _paymentMethod,
        createdBy: ref.read(currentUserIdProvider),
        number: 'PO-${DateTime.now().millisecondsSinceEpoch}',
      );

      await ref.read(purchaseControllerProvider).createPurchase(purchase);
      if (mounted) {
        NotificationService.showSuccess(context, 'Enregistré avec succès');
        Navigator.pop(context);
      }
    } catch (e) {
      NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(rawMaterialsProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nouvel Approvisionnement"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: const Text("VALIDER"),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item side
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildItemForm(products, theme),
                          const SizedBox(height: 16),
                          _buildItemList(theme),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 32),
                    // Summary side
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildPurchaseInfo(suppliers, theme),
                            ),
                          ),
                          const Divider(),
                          _buildTotalSummary(theme),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading ? const CircularProgressIndicator() : const Text("ENREGISTRER L'ACHAT"),
                          ),
                        ],
                      ),
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

  Widget _buildItemForm(List<Product> products, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Product>(
              initialValue: _selectedProduct,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Produit / Matière Première",
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: products.map((p) {
                final colors = theme.colorScheme;
                final badgeBg = p.type == ProductType.rawMaterial
                    ? colors.tertiaryContainer
                    : colors.secondaryContainer;
                final badgeFg = p.type == ProductType.rawMaterial
                    ? colors.onTertiaryContainer
                    : colors.onSecondaryContainer;
                return DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.type == ProductType.rawMaterial ? "MP" : "PF",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                      Text(
                        "${p.unitPrice} CFA",
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedProduct = v;
                  if (v != null) {
                    _unitsPerLotController.text = v.unitsPerLot.toString();
                    _useLots = v.isRawMaterial && v.name.toLowerCase().contains('emballage');
                    // Reset quantity focus to avoid carrying over from previous selection
                    FocusScope.of(context).requestFocus(FocusNode());
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: _useLots ? "Nb de Lots" : "Quantité",
                      suffixText: _useLots ? "lots" : _selectedProduct?.unit,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: "Prix Total (Optionnel)",
                      hintText: _selectedProduct != null ? "Auto: ${_selectedProduct!.unitPrice} /u" : null,
                      suffixText: "CFA",
                      helperText: "Laissez vide pour utiliser le prix catalogue",
                      helperMaxLines: 2,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addItem, icon: const Icon(Icons.add)),
              ],
            ),
            if (_useLots) ...[
              const SizedBox(height: 8),
              _buildConversionPreview(theme),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildConversionPreview(ThemeData theme) {
    final qty = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
    final price = int.tryParse(_priceController.text) ?? 0;
    final unitsPerLot = int.tryParse(_unitsPerLotController.text) ?? 1000;
    
    final totalUnits = (qty * unitsPerLot).round();
    final unitPrice = totalUnits > 0 ? (price / unitsPerLot).toStringAsFixed(1) : "0";

    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            "= $totalUnits unités (Catalog: ${_selectedProduct?.unitPrice ?? 0} CFA/u)",
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(ThemeData theme) {
    return Expanded(
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final PurchaseItem item = _items[index];
          return ListTile(
            title: Text(item.productName),
            subtitle: Text("${item.quantity} x ${item.unitPrice} CFA"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${item.totalPrice} CFA", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _items.removeAt(index)),
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurchaseInfo(List<Supplier> suppliers, ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<Supplier>(
          initialValue: _selectedSupplier,
          decoration: const InputDecoration(labelText: "Fournisseur"),
          items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (v) => setState(() => _selectedSupplier = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _paidAmountController,
          decoration: const InputDecoration(labelText: "Montant Payé (Acompte)"),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PurchaseStatus>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: "Type d'opération"),
          items: const [
            DropdownMenuItem(value: PurchaseStatus.draft, child: Text("Bon de Commande (PO)")),
            DropdownMenuItem(value: PurchaseStatus.validated, child: Text("Achat direct (Reçu)")),
          ],
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<PaymentMethod>(
          initialValue: _paymentMethod,
          decoration: const InputDecoration(
            labelText: "Mode de paiement",
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          items: const [
            DropdownMenuItem(value: PaymentMethod.cash, child: Text("Espèces (Caisse)")),
            DropdownMenuItem(value: PaymentMethod.mobileMoney, child: Text("Mobile Money")),
          ],
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
      ],
    );
  }

  Widget _buildTotalSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:"),
              Text("$_totalAmount CFA", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

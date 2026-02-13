
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/supplier.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';

class PurchaseEntryDialog extends ConsumerStatefulWidget {
  const PurchaseEntryDialog({super.key, this.initialProduct});

  final Product? initialProduct;

  @override
  ConsumerState<PurchaseEntryDialog> createState() => _PurchaseEntryDialogState();
}

class _PurchaseEntryDialogState extends ConsumerState<PurchaseEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Item Entry State
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  // List State
  final List<PurchaseItem> _items = [];
  
  // Global Purchase State
  Supplier? _selectedSupplier;
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _selectedProduct = widget.initialProduct;
      if (widget.initialProduct!.purchasePrice != null && widget.initialProduct!.purchasePrice != 0) {
        _priceController.text = widget.initialProduct!.purchasePrice.toString();
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_selectedProduct == null) {
       NotificationService.showWarning(context, 'Veuillez sélectionner un produit');
       return;
    }

    final quantity = int.tryParse(_quantityController.text);
    final price = int.tryParse(_priceController.text);

    if (quantity == null || quantity <= 0) {
      NotificationService.showWarning(context, 'Quantité invalide');
      return;
    }
    
    if (price == null || price <= 0) {
      NotificationService.showWarning(context, 'Prix invalide');
      return;
    }

    setState(() {
      _items.add(PurchaseItem(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        quantity: quantity,
        purchasePrice: price,
        totalPrice: quantity * price,
      ));
      
      // Reset item inputs
      _selectedProduct = null;
      _quantityController.clear();
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  int get _totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

  Future<void> _submit() async {
    if (_items.isEmpty) {
      NotificationService.showWarning(context, 'Veuillez ajouter au moins un produit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmount = _totalAmount;
      final paidAmount = int.tryParse(_paidAmountController.text) ?? totalAmount;
      final debtAmount = totalAmount - paidAmount;

      // VALIDATION: Credit Purchase requires a Supplier
      if (debtAmount > 0 && _selectedSupplier == null) {
        NotificationService.showWarning(
          context, 
          'Veuillez sélectionner un fournisseur pour les achats à crédit',
        );
        setState(() => _isLoading = false);
        return;
      }

      final purchase = Purchase(
        id: '', 
        enterpriseId: '', 
        date: DateTime.now(),
        items: List.from(_items),
        totalAmount: totalAmount,
        supplierId: _selectedSupplier?.id,
        paidAmount: paidAmount,
        debtAmount: debtAmount > 0 ? debtAmount : 0,
        notes: _notesController.text.trim(),
      );

      await ref.read(storeControllerProvider).createPurchase(purchase);

      if (mounted) {
        NotificationService.showSuccess(context, 'Approvisionnement enregistré');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'enregistrement: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 800), // Wider for table
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nouvel Approvisionnement',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 32),
            
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Item Entry & List
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Item Entry Form
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ajouter un produit',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              productsAsync.when(
                                data: (products) => DropdownButtonFormField<Product>(
                                  value: _selectedProduct != null 
                                      ? products.where((p) => p.id == _selectedProduct!.id).firstOrNull 
                                      : null,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Produit',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.inventory_2_outlined),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: products.map((product) {
                                    return DropdownMenuItem(
                                      value: product,
                                      child: Text(
                                        product.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedProduct = value;
                                      if (value != null && (value.purchasePrice ?? 0) > 0) {
                                        _priceController.text = value.purchasePrice.toString();
                                      }
                                    });
                                  },
                                ),
                                loading: () => const LinearProgressIndicator(),
                                error: (_, __) => const Text('Erreur chargement produits'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantité',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _priceController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prix Unit.',
                                        border: OutlineInputBorder(),
                                        suffixText: 'FCFA',
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: _addItem,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Ajouter'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Item List
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _items.isEmpty 
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shopping_basket_outlined, size: 48, color: theme.colorScheme.secondary),
                                      const SizedBox(height: 8),
                                      Text('Aucun produit ajouté', style: theme.textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  dataRowMinHeight: 40,
                                  dataRowMaxHeight: 60,
                                  columns: const [
                                    DataColumn(label: Text('Produit')),
                                    DataColumn(label: Text('Qté', textAlign: TextAlign.right)),
                                    DataColumn(label: Text('Prix/U', textAlign: TextAlign.right)),
                                    DataColumn(label: Text('Total', textAlign: TextAlign.right)),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: _items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    return DataRow(cells: [
                                      DataCell(Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text('${item.quantity}')),
                                      DataCell(Text(CurrencyFormatter.formatFCFA(item.purchasePrice))),
                                      DataCell(Text(CurrencyFormatter.formatFCFA(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => _removeItem(index),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // RIGHT COLUMN: Global Info & Actions
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Informations Globales',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 32),
                            
                            // Total Display
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text('Montant Total', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.formatFCFA(_totalAmount),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Supplier
                            ref.watch(suppliersProvider).when(
                              data: (suppliers) => DropdownButtonFormField<Supplier>(
                                value: _selectedSupplier,
                                decoration: const InputDecoration(
                                  labelText: 'Fournisseur (Optionnel)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.local_shipping_outlined),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: suppliers.map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedSupplier = v),
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const SizedBox(),
                            ),
                            const SizedBox(height: 16),
                            
                            // Paid Amount
                            TextField(
                              controller: _paidAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Montant Payé (Acompte)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payments_outlined),
                                suffixText: 'FCFA',
                                hintText: 'Laisser vide si tout payé',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            
                            // Notes
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note_alt_outlined),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check),
                              label: const Text('ENREGISTRER'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

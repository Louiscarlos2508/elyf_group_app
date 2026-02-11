import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/purchase.dart';

/// Dialog simplifié pour réapprovisionner un seul produit.
class RestockDialog extends ConsumerStatefulWidget {
  const RestockDialog({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends ConsumerState<RestockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _supplierController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec le prix unitaire × 1
    final unitPrice = widget.product.purchasePrice ?? 0;
    _priceController.text = unitPrice > 0 ? unitPrice.toString() : '';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  int _calculateUnitPrice() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final totalPrice = int.tryParse(_priceController.text) ?? 0;
    if (qty <= 0) return 0;
    return (totalPrice / qty).round();
  }

  Future<void> _saveRestock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final enterpriseId =
        ref.read(activeEnterpriseProvider).value?.id ?? 'default';

    try {
      final qty = int.parse(_quantityController.text);
      final totalPrice = int.parse(_priceController.text);
      final unitPrice = (totalPrice / qty).round();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomPart = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
      final purchase = Purchase(
        id: 'local_purchase_${timestamp}_$randomPart',
        enterpriseId: enterpriseId,
        date: DateTime.now(),
        items: [
          PurchaseItem(
            productId: widget.product.id,
            productName: widget.product.name,
            quantity: qty,
            purchasePrice: unitPrice,
            totalPrice: totalPrice,
          ),
        ],
        totalAmount: totalPrice,
        supplier: _supplierController.text.isEmpty
            ? null
            : _supplierController.text.trim(),
      );

      final controller = ref.read(storeControllerProvider);

      // Créer l'achat
      await controller.createPurchase(purchase);

      // Créer la dépense associée
      final expense = Expense(
        id: 'local_expense_${purchase.id.replaceFirst('local_purchase_', '')}',
        enterpriseId: enterpriseId,
        label: 'Achat: ${widget.product.name} (x$qty)',
        amountCfa: totalPrice,
        category: ExpenseCategory.stock,
        date: DateTime.now(),
        notes: purchase.supplier != null
            ? 'Fournisseur: ${purchase.supplier}'
            : null,
      );
      await controller.createExpense(expense);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(purchasesProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(expensesProvider);
      NotificationService.showSuccess(
        context,
        '+$qty ${widget.product.name} ajouté au stock (dépense enregistrée)',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.inventory, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réapprovisionner',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Stock actuel: ${widget.product.stock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        prefixIcon: Icon(Icons.add_box),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        final qty = int.tryParse(v);
                        if (qty == null || qty <= 0) return 'Min 1';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix total',
                        suffixText: 'FCFA',
                        prefixIcon: Icon(Icons.payments),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur (optionnel)',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prix unitaire:', style: theme.textTheme.titleMedium),
                    Text(
                      CurrencyFormatter.formatFCFA(_calculateUnitPrice()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _saveRestock,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Confirmer'),
        ),
      ],
    );
  }
}

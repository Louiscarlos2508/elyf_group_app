import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/entities/attached_file.dart';
import '../../../../shared/presentation/widgets/file_attachment_field.dart';
import '../../application/providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/purchase.dart';
import 'purchase_form_footer.dart';
import 'purchase_form_header.dart';
import 'purchase_item_form.dart';
import 'purchase_items_list.dart';

class PurchaseFormDialog extends ConsumerStatefulWidget {
  const PurchaseFormDialog({super.key});

  @override
  ConsumerState<PurchaseFormDialog> createState() =>
      _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends ConsumerState<PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  final List<PurchaseItemForm> _items = [];
  List<AttachedFile> _attachedFiles = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.quantityController.dispose();
      item.priceController.dispose();
    }
    super.dispose();
  }

  void _addItem(Product product) {
    setState(() {
      _items.add(PurchaseItemForm(
        product: product,
        quantityController: TextEditingController(text: '1'),
        priceController: TextEditingController(
          text: product.purchasePrice?.toString() ?? '',
        ),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _items[index];
      item.quantityController.dispose();
      item.priceController.dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  int _calculateTotal() {
    return _items.fold(0, (sum, item) {
      final qty = int.tryParse(item.quantityController.text) ?? 0;
      final price = int.tryParse(item.priceController.text) ?? 0;
      return sum + (qty * price);
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un produit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final purchaseItems = _items.map((item) {
        final qty = int.parse(item.quantityController.text);
        final price = int.parse(item.priceController.text);
        return PurchaseItem(
          productId: item.product.id,
          productName: item.product.name,
          quantity: qty,
          purchasePrice: price,
          totalPrice: qty * price,
        );
      }).toList();

      final purchase = Purchase(
        id: 'purchase-${DateTime.now().millisecondsSinceEpoch}',
        date: _selectedDate,
        items: purchaseItems,
        totalAmount: _calculateTotal(),
        supplier: _supplierController.text.isEmpty
            ? null
            : _supplierController.text.trim(),
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        attachedFiles: _attachedFiles.isEmpty ? null : _attachedFiles,
      );

      await ref.read(storeControllerProvider).createPurchase(purchase);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(purchasesProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(lowStockProductsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achat enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nouvel Achat',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      productsAsync.when(
                        data: (products) {
                          final availableProducts = products
                              .where((p) => !_items.any((item) => item.product.id == p.id))
                              .toList();
                          return PurchaseFormHeader(
                            supplierController: _supplierController,
                            selectedDate: _selectedDate,
                            onDateSelected: () => _selectDate(context),
                            products: availableProducts,
                            onProductSelected: _addItem,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Erreur de chargement'),
                      ),
                      const SizedBox(height: 16),
                      PurchaseItemsList(
                        items: _items,
                        onRemoveItem: _removeItem,
                        onCalculateTotal: _calculateTotal,
                      ),
                      const SizedBox(height: 16),
                      FileAttachmentField(
                        attachedFiles: _attachedFiles,
                        onFilesChanged: (files) {
                          setState(() => _attachedFiles = files);
                        },
                      ),
                      const SizedBox(height: 16),
                      PurchaseFormFooter(
                        totalAmount: _calculateTotal(),
                        notesController: _notesController,
                        isLoading: _isLoading,
                        onCancel: () => Navigator.of(context).pop(),
                        onSave: _savePurchase,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelector(ThemeData theme, List<Product> products) {
    final availableProducts = products
        .where((p) => !_items.any((item) => item.product.id == p.id))
        .toList();

    if (availableProducts.isEmpty) {
      return const Text('Tous les produits ont été ajoutés');
    }

    return DropdownButtonFormField<Product>(
      decoration: const InputDecoration(
        labelText: 'Ajouter un produit',
        prefixIcon: Icon(Icons.add_shopping_cart),
      ),
      items: availableProducts.map((product) {
        return DropdownMenuItem(
          value: product,
          child: Text('${product.name} (${product.price} FCFA)'),
        );
      }).toList(),
      onChanged: (product) {
        if (product != null) _addItem(product);
      },
    );
  }

}


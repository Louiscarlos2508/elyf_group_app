import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/product.dart';
import 'product_form_fields.dart';
import 'product_form_footer.dart';
import 'product_image_selector.dart';
import 'package:elyf_groupe_app/shared/utils/form_helper_mixin.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _purchasePriceController.text =
          widget.product!.purchasePrice?.toString() ?? '';
      _stockController.text = widget.product!.stock.toString();
      _descriptionController.text = widget.product!.description ?? '';
      _categoryController.text = widget.product!.category ?? '';
      _barcodeController.text = widget.product!.barcode ?? '';
      _imageUrlController.text = widget.product!.imageUrl ?? '';
      // Note: Pour les produits existants avec imageUrl, on garde l'URL
      // Pour une nouvelle image sélectionnée, on utilisera _selectedImage
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        // Stock initial (optionnel, 0 par défaut)
        final stockInitial = widget.product == null
            ? (int.tryParse(_stockController.text) ?? 0)
            : widget.product!.stock;

        // Prix total d'achat (si stock > 0)
        final totalPurchasePrice = _purchasePriceController.text.isEmpty
            ? null
            : int.tryParse(_purchasePriceController.text);

        // Utiliser ProductCalculationService pour calculer le prix unitaire d'achat
        final calculationService = ref.read(productCalculationServiceProvider);
        final unitPurchasePrice = calculationService.calculateUnitPurchasePrice(
          stockInitial: stockInitial,
          totalPurchasePrice: totalPurchasePrice,
        );

        final product = Product(
          id:
              widget.product?.id ??
              'prod-${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          price: int.parse(_priceController.text),
          stock: stockInitial,
          purchasePrice: unitPurchasePrice,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _categoryController.text.isEmpty
              ? null
              : _categoryController.text.trim(),
          barcode: _barcodeController.text.isEmpty
              ? null
              : _barcodeController.text.trim(),
          imageUrl: _selectedImage != null
              ? _selectedImage!.path
              : (_imageUrlController.text.isEmpty
                    ? null
                    : _imageUrlController.text.trim()),
        );

        if (widget.product == null) {
          await ref.read(storeControllerProvider).createProduct(product);

          // Si stock initial et prix total sont définis, créer une dépense automatique
          if (stockInitial > 0 && totalPurchasePrice != null) {
            final expense = Expense(
              id: 'expense-stock-${product.id}',
              label: 'Stock initial: ${product.name}',
              amountCfa: totalPurchasePrice,
              category: ExpenseCategory.other,
              date: DateTime.now(),
              notes:
                  'Stock initial de $stockInitial unité(s) à $unitPurchasePrice FCFA/unité',
            );
            await ref.read(storeControllerProvider).createExpense(expense);
            ref.invalidate(expensesProvider);
          }
        } else {
          await ref.read(storeControllerProvider).updateProduct(product);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ref.invalidate(productsProvider);
          ref.invalidate(lowStockProductsProvider);
        }

        return widget.product == null
            ? 'Produit créé avec succès${stockInitial > 0 && totalPurchasePrice != null ? ' (dépense enregistrée)' : ''}'
            : 'Produit mis à jour';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product == null
                              ? 'Nouveau Produit'
                              : 'Modifier le Produit',
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
                  const SizedBox(height: 24),
                  ProductFormFields(
                    nameController: _nameController,
                    priceController: _priceController,
                    purchasePriceController: _purchasePriceController,
                    stockController: _stockController,
                    categoryController: _categoryController,
                    barcodeController: _barcodeController,
                    descriptionController: _descriptionController,
                    isEditing: widget.product != null,
                  ),
                  const SizedBox(height: 16),
                  ProductImageSelector(
                    initialImageUrl: widget.product?.imageUrl,
                    onImageSelected: (file) {
                      setState(() => _selectedImage = file);
                    },
                  ),
                  const SizedBox(height: 24),
                  ProductFormFooter(
                    isLoading: _isLoading,
                    isEditing: widget.product != null,
                    onCancel: () => Navigator.of(context).pop(),
                    onSave: _saveProduct,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

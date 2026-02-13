import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';

class ProductFormFields extends ConsumerStatefulWidget {
  const ProductFormFields({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.purchasePriceController,
    required this.stockController,
    required this.categoryController,
    required this.barcodeController,
    required this.thresholdController,
    required this.descriptionController,
    this.isEditing = false,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchasePriceController;
  final TextEditingController stockController;
  final TextEditingController categoryController;
  final TextEditingController barcodeController;
  final TextEditingController thresholdController;
  final TextEditingController descriptionController;
  final bool isEditing;

  @override
  ConsumerState<ProductFormFields> createState() => _ProductFormFieldsState();
}

class _ProductFormFieldsState extends ConsumerState<ProductFormFields> {
  int _calculateUnitPrice() {
    final qty = int.tryParse(widget.stockController.text) ?? 0;
    final totalPrice = int.tryParse(widget.purchasePriceController.text) ?? 0;
    if (qty <= 0) return 0;
    return (totalPrice / qty).round();
  }

  @override
  void initState() {
    super.initState();
    widget.stockController.addListener(_onFieldChanged);
    widget.purchasePriceController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.stockController.removeListener(_onFieldChanged);
    widget.purchasePriceController.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPrice = _calculateUnitPrice();
    final hasStock = (int.tryParse(widget.stockController.text) ?? 0) > 0;
    final hasPurchasePrice =
        (int.tryParse(widget.purchasePriceController.text) ?? 0) > 0;

    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        // Nom du produit
        TextFormField(
          controller: widget.nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit *',
            prefixIcon: Icon(Icons.shopping_bag),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
        ),
        const SizedBox(height: 16),

        // Prix de vente
        TextFormField(
          controller: widget.priceController,
          decoration: const InputDecoration(
            labelText: 'Prix de vente (FCFA) *',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (int.tryParse(v) == null || int.parse(v) <= 0) {
              return 'Prix invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Stock initial (optionnel sauf en édition)
        TextFormField(
          controller: widget.stockController,
          decoration: InputDecoration(
            labelText: widget.isEditing
                ? 'Stock actuel (lecture seule)'
                : 'Stock initial (optionnel)',
            prefixIcon: const Icon(Icons.inventory_2),
            helperText: widget.isEditing
                ? 'Modifiable via réapprovisionnement'
                : 'Laisser vide pour approvisionner plus tard',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !widget.isEditing,
        ),
        const SizedBox(height: 16),

        // Prix total d'achat (si stock > 0)
        TextFormField(
          controller: widget.purchasePriceController,
          decoration: InputDecoration(
            labelText: hasStock
                ? 'Prix total d\'achat (FCFA)'
                : 'Prix d\'achat',
            prefixIcon: const Icon(Icons.payments),
            helperText: widget.isEditing
                ? 'Modifiable via réapprovisionnement'
                : hasStock
                ? 'Montant total payé au fournisseur'
                : 'Définir le stock d\'abord',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !widget.isEditing && hasStock,
        ),

        // Affichage du prix unitaire calculé
        if (!widget.isEditing && hasStock && hasPurchasePrice) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix unitaire d\'achat:',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${CurrencyFormatter.formatFCFA(unitPrice)} FCFA',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Catégorie (Dropdown)
        categoriesAsync.when(
          data: (categories) => DropdownButtonFormField<String>(
            value: widget.categoryController.text.isEmpty ? null : widget.categoryController.text,
            decoration: const InputDecoration(
              labelText: 'Catégorie (optionnel)',
              prefixIcon: Icon(Icons.category),
            ),
            items: categories.map((c) => DropdownMenuItem(
              value: c.id,
              child: Row(
                children: [
                   Container(
                     width: 12,
                     height: 12,
                     decoration: BoxDecoration(
                       color: c.colorValue != null ? Color(c.colorValue!) : Colors.grey,
                       shape: BoxShape.circle,
                     ),
                   ),
                   const SizedBox(width: 8),
                   Text(c.name),
                ],
              ),
            )).toList(),
            onChanged: (val) {
              widget.categoryController.text = val ?? '';
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => TextFormField(
            controller: widget.categoryController,
            decoration: const InputDecoration(
              labelText: 'Catégorie (chargement en erreur)',
              prefixIcon: Icon(Icons.category),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Code-barres
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Code-barres (optionnel)',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                // Future implementation: Scan barcode
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Seuil d'alerte de stock
        TextFormField(
          controller: widget.thresholdController,
          decoration: const InputDecoration(
            labelText: 'Seuil d\'alerte stock',
            prefixIcon: Icon(Icons.warning_amber_rounded),
            helperText: 'Niveau en dessous duquel le stock est considéré comme faible',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: widget.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optionnel)',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}

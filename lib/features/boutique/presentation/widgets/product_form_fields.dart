import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductFormFields extends StatelessWidget {
  const ProductFormFields({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.purchasePriceController,
    required this.stockController,
    required this.categoryController,
    required this.barcodeController,
    required this.descriptionController,
    this.isEditing = false,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchasePriceController;
  final TextEditingController stockController;
  final TextEditingController categoryController;
  final TextEditingController barcodeController;
  final TextEditingController descriptionController;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit *',
            prefixIcon: Icon(Icons.shopping_bag),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: priceController,
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: isEditing
                      ? 'Stock actuel (lecture seule)'
                      : 'Stock initial *',
                  prefixIcon: const Icon(Icons.inventory_2),
                  helperText: isEditing
                      ? 'Le stock ne peut être modifié que via les achats et ventes'
                      : 'Le stock sera modifié uniquement via les achats et ventes',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !isEditing,
                validator: isEditing
                    ? null
                    : (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (int.tryParse(v) == null || int.parse(v) < 0) {
                          return 'Stock invalide';
                        }
                        return null;
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: purchasePriceController,
          decoration: InputDecoration(
            labelText: 'Prix d\'achat (FCFA)',
            prefixIcon: const Icon(Icons.shopping_cart),
            helperText: isEditing
                ? 'Modifiable uniquement via les achats'
                : 'Si défini avec stock initial, une dépense sera créée automatiquement',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !isEditing,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Catégorie (optionnel)',
            prefixIcon: Icon(Icons.category),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: barcodeController,
          decoration: const InputDecoration(
            labelText: 'Code-barres (optionnel)',
            prefixIcon: Icon(Icons.qr_code),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
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


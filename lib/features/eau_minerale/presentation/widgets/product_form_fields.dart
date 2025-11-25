import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';

/// Form fields for product form dialog.
class ProductFormFields extends StatelessWidget {
  const ProductFormFields({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.unitController,
    required this.type,
    required this.onTypeChanged,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController unitController;
  final ProductType type;
  final void Function(ProductType) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit',
            prefixIcon: Icon(Icons.inventory_2),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ProductType>(
          value: type,
          decoration: const InputDecoration(
            labelText: 'Type',
            prefixIcon: Icon(Icons.category),
          ),
          items: const [
            DropdownMenuItem(
              value: ProductType.finishedGood,
              child: Text('Produit Fini (PF)'),
            ),
            DropdownMenuItem(
              value: ProductType.rawMaterial,
              child: Text('Matière Première (MP)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) onTypeChanged(v);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire (CFA)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final price = int.tryParse(v);
                  if (price == null || price < 0) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unité',
                  prefixIcon: Icon(Icons.straighten),
                  hintText: 'kg, Unité, etc.',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


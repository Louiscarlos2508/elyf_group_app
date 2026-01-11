import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart' show productValidationServiceProvider;
import '../../domain/entities/product.dart';

/// Form fields for product form dialog.
class ProductFormFields extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser le service de validation pour extraire la logique métier
    final validationService = ref.read(productValidationServiceProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit',
            prefixIcon: Icon(Icons.inventory_2),
          ),
          validator: validationService.validateName,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ProductType>(
          initialValue: type,
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
                validator: validationService.validatePrice,
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
                validator: validationService.validateUnit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


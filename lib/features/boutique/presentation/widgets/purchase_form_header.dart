import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import 'purchase_item_form.dart';

class PurchaseFormHeader extends StatelessWidget {
  const PurchaseFormHeader({
    super.key,
    required this.supplierController,
    required this.selectedDate,
    required this.onDateSelected,
    required this.products,
    required this.onProductSelected,
  });

  final TextEditingController supplierController;
  final DateTime selectedDate;
  final VoidCallback onDateSelected;
  final List<Product> products;
  final void Function(Product) onProductSelected;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableProducts = products
        .where((p) => true) // Will be filtered by parent
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur (optionnel)',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: onDateSelected,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'achat',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(selectedDate)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Produits achetés',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const Text('Tous les produits ont été ajoutés')
        else
          DropdownButtonFormField<Product>(
            decoration: const InputDecoration(
              labelText: 'Ajouter un produit',
              prefixIcon: Icon(Icons.add_shopping_cart),
            ),
            items: products.map((product) {
              return DropdownMenuItem(
                value: product,
                child: Text('${product.name} (${product.price} FCFA)'),
              );
            }).toList(),
            onChanged: (product) {
              if (product != null) onProductSelected(product);
            },
          ),
      ],
    );
  }
}


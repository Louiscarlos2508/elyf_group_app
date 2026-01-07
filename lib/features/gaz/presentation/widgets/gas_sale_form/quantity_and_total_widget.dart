import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared.dart';
import '../../../domain/entities/cylinder.dart';

/// Widget pour saisir la quantité et afficher le total.
class QuantityAndTotalWidget extends StatelessWidget {
  const QuantityAndTotalWidget({
    super.key,
    required this.quantityController,
    required this.selectedCylinder,
    required this.availableStock,
    required this.unitPrice,
    required this.onQuantityChanged,
  });

  final TextEditingController quantityController;
  final Cylinder? selectedCylinder;
  final int availableStock;
  final double unitPrice;
  final VoidCallback onQuantityChanged;

  double get _totalAmount {
    if (selectedCylinder == null || unitPrice == 0.0) return 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 0;
    return unitPrice * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: quantityController,
          decoration: InputDecoration(
            labelText: 'Quantité *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une quantité';
            }
            final quantity = int.tryParse(value);
            if (quantity == null || quantity <= 0) {
              return 'Quantité invalide';
            }
            if (quantity > availableStock) {
              return 'Stock insuffisant ($availableStock disponible)';
            }
            return null;
          },
          onChanged: (_) => onQuantityChanged(),
        ),
        if (selectedCylinder != null && quantityController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(_totalAmount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


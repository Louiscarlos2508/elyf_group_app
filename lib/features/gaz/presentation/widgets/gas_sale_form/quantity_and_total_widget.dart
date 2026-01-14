import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/services/gas_calculation_service.dart';

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
    final quantity = int.tryParse(quantityController.text) ?? 0;
    return GasCalculationService.calculateTotalAmount(
      cylinder: selectedCylinder,
      unitPrice: unitPrice,
      quantity: quantity,
    );
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            return GasCalculationService.validateQuantityText(
              quantityText: value,
              availableStock: availableStock,
            );
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_financial_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_sales_calculation_service.dart';

/// Widget pour saisir la quantité et afficher le total.
class QuantityAndTotalWidget extends StatelessWidget {
  const QuantityAndTotalWidget({
    super.key,
    required this.quantityController,
    required this.selectedCylinder,
    required this.availableStock,
    required this.unitPriceController,
    required this.onQuantityOrPriceChanged,
  });

  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final Cylinder? selectedCylinder;
  final int availableStock;
  final VoidCallback onQuantityOrPriceChanged;

  double get _totalAmount {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0.0;
    return GazFinancialCalculationService.calculateTotalAmount(
      cylinder: selectedCylinder,
      unitPrice: price,
      quantity: quantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  return GazSalesCalculationService.validateQuantityText(
                    quantityText: value,
                    availableStock: availableStock,
                  );
                },
                onChanged: (_) => onQuantityOrPriceChanged(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: unitPriceController,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire *',
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatoire';
                  if (double.tryParse(value) == null) return 'Invalide';
                  return null;
                },
                onChanged: (_) => onQuantityOrPriceChanged(),
              ),
            ),
          ],
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

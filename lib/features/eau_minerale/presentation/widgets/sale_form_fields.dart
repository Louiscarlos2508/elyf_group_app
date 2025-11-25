import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/customer_repository.dart';
import 'sale_total_display.dart';

/// Form fields for sale form.
class SaleFormFields extends StatelessWidget {
  const SaleFormFields({
    super.key,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.customerCnibController,
    required this.quantityController,
    required this.amountPaidController,
    required this.notesController,
    required this.selectedProduct,
    required this.totalPrice,
    required this.remainingAmount,
    required this.onQuantityChanged,
    required this.onAmountPaidChanged,
    required this.formatCurrency,
  });

  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController customerCnibController;
  final TextEditingController quantityController;
  final TextEditingController amountPaidController;
  final TextEditingController notesController;
  final Product? selectedProduct;
  final int? totalPrice;
  final int? remainingAmount;
  final VoidCallback onQuantityChanged;
  final VoidCallback onAmountPaidChanged;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: customerNameController,
          decoration: const InputDecoration(
            labelText: 'Nom du client',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: customerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: customerCnibController,
          decoration: const InputDecoration(
            labelText: 'CNIB (optionnel)',
            prefixIcon: Icon(Icons.badge),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantité',
            prefixIcon: Icon(Icons.inventory_2),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => onQuantityChanged(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final qty = int.tryParse(v);
            if (qty == null || qty <= 0) return 'Quantité invalide';
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (totalPrice != null) SaleTotalDisplay(totalPrice: totalPrice!),
        if (totalPrice != null) const SizedBox(height: 16),
        TextFormField(
          controller: amountPaidController,
          decoration: InputDecoration(
            labelText: 'Montant payé (CFA)',
            prefixIcon: const Icon(Icons.attach_money),
            helperText: totalPrice != null && remainingAmount != null
                ? remainingAmount! > 0
                    ? 'Crédit restant: ${formatCurrency(remainingAmount!)}'
                    : 'Paiement complet'
                : null,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => onAmountPaidChanged(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final amount = int.tryParse(v);
            if (amount == null || amount < 0) return 'Montant invalide';
            if (totalPrice != null && amount > totalPrice!) {
              return 'Ne peut pas dépasser le total';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}


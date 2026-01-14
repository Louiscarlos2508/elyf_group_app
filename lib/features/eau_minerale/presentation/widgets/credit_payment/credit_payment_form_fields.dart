import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/sale.dart';

/// Form fields widget for credit payment dialog.
class CreditPaymentFormFields extends StatelessWidget {
  const CreditPaymentFormFields({
    super.key,
    required this.amountController,
    required this.notesController,
    required this.selectedSale,
    required this.isLoadingSales,
    required this.onFillFullAmount,
  });

  final TextEditingController amountController;
  final TextEditingController notesController;
  final Sale? selectedSale;
  final bool isLoadingSales;
  final VoidCallback onFillFullAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: 'Montant payé (CFA)',
            prefixIcon: const Icon(Icons.attach_money),
            helperText: selectedSale != null
                ? 'Maximum: ${CurrencyFormatter.formatCFA(selectedSale!.remainingAmount)}'
                : 'Sélectionnez une vente',
            suffixIcon: selectedSale != null
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: onFillFullAmount,
                    tooltip: 'Remplir le montant total',
                  )
                : null,
          ),
          keyboardType: TextInputType.number,
          enabled: selectedSale != null && !isLoadingSales,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final amount = int.tryParse(v);
            if (amount == null || amount <= 0) return 'Montant invalide';
            if (selectedSale != null &&
                amount > selectedSale!.remainingAmount) {
              return 'Ne peut pas dépasser le reste à payer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            prefixIcon: Icon(Icons.note_outlined),
            helperText: 'Ajouter une note pour ce paiement',
          ),
          maxLines: 2,
          enabled: !isLoadingSales,
        ),
      ],
    );
  }
}

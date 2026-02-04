import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/sale.dart';

enum PaymentMode { cash, orangeMoney, mixed }

/// Form fields widget for credit payment dialog.
class CreditPaymentFormFields extends StatelessWidget {
  const CreditPaymentFormFields({
    super.key,
    required this.cashController,
    required this.omController,
    required this.notesController,
    required this.selectedSale,
    required this.isLoadingSales,
    required this.paymentMode,
    required this.onFillFullAmount,
  });

  final TextEditingController cashController;
  final TextEditingController omController;
  final TextEditingController notesController;
  final Sale? selectedSale;
  final bool isLoadingSales;
  final PaymentMode paymentMode;
  final VoidCallback onFillFullAmount;

  @override
  Widget build(BuildContext context) {
    
    final showCash = paymentMode == PaymentMode.cash || paymentMode == PaymentMode.mixed;
    final showOm = paymentMode == PaymentMode.orangeMoney || paymentMode == PaymentMode.mixed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCash)
              Expanded(
                child: TextFormField(
                  controller: cashController,
                  decoration: const InputDecoration(
                    labelText: 'Cash',
                    prefixIcon: Icon(Icons.money),
                    suffixText: 'CFA',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: selectedSale != null && !isLoadingSales,
                  validator: (v) => _validateAmount(v, cashController, omController),
                ),
              ),
            if (showCash && showOm) const SizedBox(width: 16),
            if (showOm)
              Expanded(
                child: TextFormField(
                  controller: omController,
                  decoration: const InputDecoration(
                    labelText: 'Orange Money',
                    prefixIcon: Icon(Icons.phone_android),
                    suffixText: 'CFA',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: selectedSale != null && !isLoadingSales,
                  validator: (v) => _validateAmount(v, cashController, omController),
                ),
              ),
          ],
        ),
        if (selectedSale != null) ...[
          const SizedBox(height: 8),
        if (selectedSale != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Reste à payer: ${CurrencyFormatter.formatCFA(selectedSale!.remainingAmount)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onFillFullAmount,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Tout payer'),
              ),
            ],
          ),
        ],
        ],
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

  String? _validateAmount(
    String? value,
    TextEditingController cashCtrl,
    TextEditingController omCtrl,
  ) {
    // Validate that at least one amount is > 0 and sum <= remaining
    final cash = int.tryParse(cashCtrl.text) ?? 0;
    final om = int.tryParse(omCtrl.text) ?? 0;
    final total = cash + om;

    if (total <= 0) return 'Total requis';
    
    if (selectedSale != null && total > selectedSale!.remainingAmount) {
      return 'Total dépasse le reste';
    }
    
    return null;
  }
}

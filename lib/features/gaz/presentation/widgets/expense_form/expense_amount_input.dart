import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input pour le montant de la dépense.
class ExpenseAmountInput extends StatelessWidget {
  const ExpenseAmountInput({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Montant (FCFA)',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un montant';
        }
        return null;
      },
    );
  }
}


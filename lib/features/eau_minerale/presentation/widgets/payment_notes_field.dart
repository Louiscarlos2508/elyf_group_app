import 'package:flutter/material.dart';

/// Reusable notes field for payment forms.
class PaymentNotesField extends StatelessWidget {
  const PaymentNotesField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Notes (optionnel)',
        prefixIcon: Icon(Icons.note),
        hintText: 'Ex: Paiement complet, Acompte, etc.',
      ),
      maxLines: 3,
    );
  }
}


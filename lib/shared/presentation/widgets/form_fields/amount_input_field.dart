import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/validators.dart';

/// Champ de saisie de montant réutilisable.
class AmountInputField extends StatelessWidget {
  const AmountInputField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Montant (FCFA) *',
    this.hintText,
    this.enabled = true,
    this.useDouble = false,
    this.icon = Icons.attach_money,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final String? hintText;
  final bool enabled;
  final bool useDouble;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? '0',
        prefixIcon: Icon(icon),
      ),
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: useDouble),
      inputFormatters: useDouble
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ]
          : [
              FilteringTextInputFormatter.digitsOnly,
            ],
      validator: validator ??
          (useDouble ? Validators.amountDouble : Validators.amount),
    );
  }
}


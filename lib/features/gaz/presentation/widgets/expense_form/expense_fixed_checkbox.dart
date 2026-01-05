import 'package:flutter/material.dart';

/// Checkbox pour indiquer si la dépense est fixe.
class ExpenseFixedCheckbox extends StatelessWidget {
  const ExpenseFixedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: const Text('Charge fixe'),
      subtitle: const Text(
        'Si coché, cette dépense est une charge fixe (ex: loyer). Sinon, c\'est une charge variable.',
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}


import 'package:flutter/material.dart';

/// Input pour les notes de la dépense.
class ExpenseNotesInput extends StatelessWidget {
  const ExpenseNotesInput({
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
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }
}


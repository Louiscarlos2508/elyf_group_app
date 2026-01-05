import 'package:flutter/material.dart';

/// Input pour la description de la dépense.
class ExpenseDescriptionInput extends StatelessWidget {
  const ExpenseDescriptionInput({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Description',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer une description';
        }
        return null;
      },
    );
  }
}


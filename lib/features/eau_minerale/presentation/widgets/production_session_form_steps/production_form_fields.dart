import 'package:flutter/material.dart';

/// Champs de formulaire pour la production (quantité, emballages, notes).
class ProductionFormFields extends StatelessWidget {
  const ProductionFormFields({
    super.key,
    required this.quantiteController,
    required this.emballagesController,
    required this.notesController,
  });

  final TextEditingController quantiteController;
  final TextEditingController emballagesController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: quantiteController,
          decoration: const InputDecoration(
            labelText: 'Quantité produite (packs)',
            prefixIcon: Icon(Icons.inventory_2),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requis';
            }
            final intValue = int.tryParse(value);
            if (intValue == null || intValue <= 0) {
              return 'Le nombre doit être un entier positif';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emballagesController,
          decoration: const InputDecoration(
            labelText: 'Emballages utilisés (packs)',
            prefixIcon: Icon(Icons.inventory_2),
            helperText: 'Optionnel',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            prefixIcon: Icon(Icons.note),
            helperText: 'Optionnel',
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

/// Widget pour saisir les informations du client (nom, téléphone, notes).
class CustomerInfoWidget extends StatelessWidget {
  const CustomerInfoWidget({
    super.key,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.notesController,
  });

  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: customerNameController,
          decoration: InputDecoration(
            labelText: 'Nom du client (optionnel)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: customerPhoneController,
          decoration: InputDecoration(
            labelText: 'Téléphone (optionnel)',
            hintText: '+226 70 00 00 00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) =>
              (v == null || v.trim().isEmpty)
                  ? null
                  : Validators.phoneBurkina(v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: 'Notes (optionnel)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.note),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

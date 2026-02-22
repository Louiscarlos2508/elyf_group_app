import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

class CustomerInfoWidget extends StatelessWidget {
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController notesController;
  final bool isRequired;

  const CustomerInfoWidget({
    super.key,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.notesController,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: customerNameController,
          decoration: InputDecoration(
            labelText: isRequired ? 'Nom du client *' : 'Nom du client (optionnel)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.person),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: customerPhoneController,
          decoration: InputDecoration(
            labelText: isRequired ? 'Téléphone *' : 'Téléphone (optionnel)',
            hintText: '+226 70 00 00 00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (isRequired && (v == null || v.trim().isEmpty)) {
              return 'Le téléphone est obligatoire';
            }
            if (v == null || v.trim().isEmpty) return null;
            return Validators.phoneBurkina(v);
          },
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

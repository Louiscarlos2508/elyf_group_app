import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

/// Customer information fields for the sale form.
class SaleCustomerFields extends StatelessWidget {
  const SaleCustomerFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.cnibController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cnibController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du client',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone),
            hintText: '+226 70 00 00 00',
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => Validators.phoneBurkina(v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: cnibController,
          decoration: const InputDecoration(
            labelText: 'CNIB (optionnel)',
            prefixIcon: Icon(Icons.badge),
          ),
        ),
      ],
    );
  }
}

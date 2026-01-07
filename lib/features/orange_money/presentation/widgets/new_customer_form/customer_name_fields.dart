import 'package:flutter/material.dart';

import '../../../domain/services/customer_service.dart';

/// Widget for first name and last name input fields.
class CustomerNameFields extends StatelessWidget {
  const CustomerNameFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prénom *',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Jean',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: CustomerService.validateFirstName,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nom *',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Dupont',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: CustomerService.validateLastName,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


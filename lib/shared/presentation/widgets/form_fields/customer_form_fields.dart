import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/validators.dart';

/// Champs de formulaire réutilisables pour les clients.
class CustomerFormFields {
  CustomerFormFields._();

  /// Champ pour le nom du client.
  static Widget nameField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String label = 'Nom *',
    String? hintText,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? 'Nom du client',
        prefixIcon: const Icon(Icons.person_outline),
      ),
      enabled: enabled,
      validator: validator ?? (v) => Validators.required(v, fieldName: 'Le nom'),
      textCapitalization: TextCapitalization.words,
    );
  }

  /// Champ pour le téléphone du client.
  static Widget phoneField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String label = 'Téléphone *',
    String? hintText,
    bool enabled = true,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? '+226 XX XX XX XX',
        prefixIcon: const Icon(Icons.phone_outlined),
      ),
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
      ],
      validator: validator ??
          (required ? Validators.phone : Validators.phoneOptional),
    );
  }

  /// Champ pour le CNIB du client (optionnel).
  static Widget cnibField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String label = 'CNIB',
    String? hintText,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? 'Numéro CNIB',
        prefixIcon: const Icon(Icons.badge_outlined),
      ),
      enabled: enabled,
      validator: validator,
      keyboardType: TextInputType.text,
    );
  }

  /// Groupe de champs client complet (nom, téléphone, CNIB).
  static Widget group({
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController cnibController,
    String? Function(String?)? nameValidator,
    String? Function(String?)? phoneValidator,
    String? Function(String?)? cnibValidator,
    bool phoneRequired = true,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nameField(
          controller: nameController,
          validator: nameValidator,
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        phoneField(
          controller: phoneController,
          validator: phoneValidator,
          required: phoneRequired,
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        cnibField(
          controller: cnibController,
          validator: cnibValidator,
          enabled: enabled,
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

import '../../../utils/validators.dart';

/// Champs de formulaire réutilisables pour les informations client.
class CustomerFormFields {
  CustomerFormFields._();

  /// Champ nom complet.
  static Widget nameField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String label = 'Nom complet',
    String? hint,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? 'Prénom et nom du client',
        prefixIcon: const Icon(Icons.person),
      ),
      textCapitalization: TextCapitalization.words,
      enabled: enabled,
      validator:
          validator ??
          ((value) => Validators.combine([
            () => Validators.required(value),
            () =>
                Validators.minLength(value, 2, customMessage: 'Nom trop court'),
          ])),
    );
  }

  /// Champ téléphone.
  static Widget phoneField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String label = 'Téléphone',
    String? hint,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? 'Numéro de téléphone (ex: +237 6XX XXX XXX)',
        prefixIcon: const Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      enabled: enabled,
      validator: validator ?? ((value) => Validators.phone(value)),
    );
  }

  /// Champ CNIB (optionnel).
  static Widget cnibField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String label = 'CNIB (optionnel)',
    String? hint,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? 'Numéro de carte d\'identité nationale',
        prefixIcon: const Icon(Icons.badge),
      ),
      keyboardType: TextInputType.text,
      enabled: enabled,
      validator: validator,
    );
  }

  /// Tous les champs client groupés.
  static List<Widget> allFields({
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController cnibController,
    String? Function(String?)? nameValidator,
    String? Function(String?)? phoneValidator,
    String? Function(String?)? cnibValidator,
    bool enabled = true,
  }) {
    return [
      nameField(
        controller: nameController,
        validator: nameValidator,
        enabled: enabled,
      ),
      const SizedBox(height: 16),
      phoneField(
        controller: phoneController,
        validator: phoneValidator,
        enabled: enabled,
      ),
      const SizedBox(height: 16),
      cnibField(
        controller: cnibController,
        validator: cnibValidator,
        enabled: enabled,
      ),
    ];
  }
}

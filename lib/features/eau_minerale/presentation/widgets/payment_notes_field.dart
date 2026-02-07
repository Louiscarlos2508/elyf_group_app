import 'package:flutter/material.dart';

/// Reusable notes field for payment forms.
class PaymentNotesField extends StatelessWidget {
  const PaymentNotesField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(
        context: context,
        label: 'Notes (optionnel)',
        icon: Icons.note_rounded,
        hintText: 'Ex: Paiement complet, Acompte, etc.',
      ),
      maxLines: 3,
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

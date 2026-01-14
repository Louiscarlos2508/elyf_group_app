import 'package:flutter/material.dart';

/// Widget réutilisable pour un champ de formulaire avec label selon le design Figma.
class FormFieldWithLabel extends StatelessWidget {
  const FormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF717182)),
            filled: true,
            fillColor: const Color(0xFFF3F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: prefixIcon,
                  )
                : null,
            prefixIconConstraints: prefixIcon != null
                ? const BoxConstraints(minWidth: 16, minHeight: 16)
                : null,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Widget for ID type selection field.
class IdTypeField extends StatelessWidget {
  const IdTypeField({
    super.key,
    required this.idType,
    this.onTap,
  });

  final String idType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Type de pièce d'identité *",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  idType,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF0A0A0A),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


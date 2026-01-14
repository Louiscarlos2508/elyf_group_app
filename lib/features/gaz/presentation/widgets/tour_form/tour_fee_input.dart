import 'package:flutter/material.dart';

/// Input pour les frais (chargement ou déchargement).
class TourFeeInput extends StatelessWidget {
  const TourFeeInput({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent, width: 1.305),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF717182),
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est requis';
                    }
                    final fee = double.tryParse(value);
                    if (fee == null || fee < 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text(
                  'FCFA',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6A7282)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

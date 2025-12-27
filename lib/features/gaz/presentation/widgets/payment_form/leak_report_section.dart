import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/collection.dart';

/// Section pour signaler les fuites par type de bouteille.
class LeakReportSection extends StatelessWidget {
  const LeakReportSection({
    super.key,
    required this.collection,
    required this.leakControllers,
  });

  final Collection collection;
  final Map<int, TextEditingController> leakControllers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(11.99),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fuite par type de bouteille (à réclamer au fournisseur)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 7.993),
          Text(
            'Le client ne paie que les bouteilles sans fuites',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: const Color(0xFFF54900),
            ),
          ),
          const SizedBox(height: 7.993),
          // Champs de saisie des fuites par poids
          ...collection.emptyBottles.entries.map((entry) {
            final weight = entry.key;
            final totalQty = entry.value;
            final controller = leakControllers[weight]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 7.993),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weight}kg (sur $totalQty)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF717182),
                    ),
                    validator: (value) {
                      final qty = int.tryParse(value ?? '0') ?? 0;
                      if (qty < 0) {
                        return 'La quantité ne peut pas être négative';
                      }
                      if (qty > totalQty) {
                        return 'La quantité ne peut pas dépasser $totalQty';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}


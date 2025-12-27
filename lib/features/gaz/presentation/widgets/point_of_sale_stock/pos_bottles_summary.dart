import 'package:flutter/material.dart';

/// Résumé des bouteilles pleines et vides.
class PosBottlesSummary extends StatelessWidget {
  const PosBottlesSummary({
    super.key,
    required this.fullBottles,
    required this.emptyBottles,
  });

  final int fullBottles;
  final int emptyBottles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Full bottles card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFB9F8CF),
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    size: 20,
                    color: Color(0xFF00A63E),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bouteilles pleines',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF4A5565),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$fullBottles',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF00A63E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Empty bottles card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFD6A7),
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Color(0xFFF54900),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bouteilles vides',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF4A5565),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$emptyBottles',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFFF54900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


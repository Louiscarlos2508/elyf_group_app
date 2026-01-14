import 'package:flutter/material.dart';

/// Card displaying bobines stock summary.
class BobinesStockCard extends StatelessWidget {
  const BobinesStockCard({super.key, required this.availableBobines});

  final int availableBobines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rotate_right,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Bobines',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBobineItem(
            context,
            'Bobines disponibles',
            'Gérées depuis Paramètres • Sorties lors des installations en production',
            availableBobines,
            'unité',
          ),
        ],
      ),
    );
  }

  Widget _buildBobineItem(
    BuildContext context,
    String name,
    String description,
    int quantity,
    String unit,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$quantity $unit',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

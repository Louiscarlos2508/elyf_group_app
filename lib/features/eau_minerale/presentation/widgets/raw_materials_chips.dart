import 'package:flutter/material.dart';

import '../../domain/entities/production.dart';

/// Widget for displaying raw materials as chips.
class RawMaterialsChips extends StatelessWidget {
  const RawMaterialsChips({
    super.key,
    required this.production,
  });

  final Production production;

  @override
  Widget build(BuildContext context) {
    if (production.rawMaterialsUsed == null ||
        production.rawMaterialsUsed!.isEmpty) {
      return Text(
        '-',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: production.rawMaterialsUsed!.map((material) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${material.productName}: ${material.quantity}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }
}


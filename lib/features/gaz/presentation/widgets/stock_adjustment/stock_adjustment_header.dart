import 'package:flutter/material.dart';

/// Header widget for stock adjustment dialog.
class StockAdjustmentHeader extends StatelessWidget {
  const StockAdjustmentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2,
            color: Color(0xFF0EA5E9),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajuster le stock',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Modifiez la quantité de bouteilles en stock',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6A7282),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

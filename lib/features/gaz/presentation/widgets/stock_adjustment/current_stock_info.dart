import 'package:flutter/material.dart';

/// Widget displaying current stock information.
class CurrentStockInfo extends StatelessWidget {
  const CurrentStockInfo({
    super.key,
    required this.quantity,
  });

  final int quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF0EA5E9),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Quantité actuelle: $quantity',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF0EA5E9),
            ),
          ),
        ],
      ),
    );
  }
}


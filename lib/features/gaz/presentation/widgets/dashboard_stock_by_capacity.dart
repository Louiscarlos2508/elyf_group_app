import 'package:flutter/material.dart';

/// Widget for Stock par capacité section (placeholder for now).
class DashboardStockByCapacity extends StatelessWidget {
  const DashboardStockByCapacity({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock par capacité',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 24),
          // Placeholder for future content
          SizedBox(
            height: 24,
            child: Center(
              child: Text(
                'Contenu à venir',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// En-tête de l'écran de vente au détail.
class RetailHeader extends StatelessWidget {
  const RetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vente au Détail',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Effectuez des ventes de bouteilles de gaz',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFF4A5565),
            ),
          ),
        ],
      ),
    );
  }
}

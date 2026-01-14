import 'package:flutter/material.dart';

/// Empty state widget when no sales are recorded - matches Figma design.
class WholesaleEmptyState extends StatelessWidget {
  const WholesaleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Container(
        height: 160,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: const Color(0xFF4A5565).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune vente enregistrée',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF4A5565),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

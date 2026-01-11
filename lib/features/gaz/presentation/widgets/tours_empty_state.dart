import 'package:flutter/material.dart';

/// Empty state widget when no tours are in progress - matches Figma design.
class ToursEmptyState extends StatelessWidget {
  const ToursEmptyState({
    super.key,
    required this.onNewTourPressed,
  });

  final VoidCallback onNewTourPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 48,
            color: const Color(0xFF6A7282).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun tour en cours',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF6A7282),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez un nouveau tour pour commencer',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFF99A1AF),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onNewTourPressed,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nouveau tour'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF030213),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


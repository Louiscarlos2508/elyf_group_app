import 'package:flutter/material.dart';

/// État vide pour la liste des fuites.
class LeakEmptyState extends StatelessWidget {
  const LeakEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune fuite signalée',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4A5565),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Signalez une fuite pour commencer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6A7282),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

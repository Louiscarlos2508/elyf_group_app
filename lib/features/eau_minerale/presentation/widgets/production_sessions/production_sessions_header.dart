import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// En-tête de l'écran des sessions de production.
class ProductionSessionsHeader extends ConsumerWidget {
  const ProductionSessionsHeader({
    super.key,
    required this.totalSessions,
    required this.onCreateSession,
  });

  final int totalSessions;
  final VoidCallback onCreateSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessions de production',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalSessions session${totalSessions > 1 ? 's' : ''} au total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(productionSessionsStateProvider),
              tooltip: 'Actualiser',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCreateSession,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle session'),
          ),
        ),
      ],
    );
  }
}


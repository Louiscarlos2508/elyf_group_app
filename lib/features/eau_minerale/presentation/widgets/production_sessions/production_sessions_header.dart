import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// En-tête de l'écran des sessions de production.
class ProductionSessionsHeader extends ConsumerWidget {
  const ProductionSessionsHeader({
    super.key,
    required this.totalSessions,
    required this.onCreateSession,
    this.hasSessionInProgress = false,
  });

  final int totalSessions;
  final VoidCallback onCreateSession;

  /// Si true, le bouton "Nouvelle session" est caché (une session est déjà en cours).
  final bool hasSessionInProgress;

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
        if (hasSessionInProgress) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Une session est en cours. Terminez-la ou finalisez-la '
                    'avant d\'en créer une nouvelle.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
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
      ],
    );
  }
}

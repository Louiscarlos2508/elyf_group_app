import 'package:flutter/material.dart';

import '../../../domain/entities/production_session.dart';

/// Widget pour l'étape "Draft" (brouillon) de la session de production.
class DraftStep extends StatelessWidget {
  const DraftStep({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Session créée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'La session de production a été créée. Cliquez sur "Démarrer" pour commencer la production.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Implémenter le démarrage de la production
                // Cela devrait mettre à jour heureDebut
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer la production'),
            ),
          ],
        ),
      ),
    );
  }
}

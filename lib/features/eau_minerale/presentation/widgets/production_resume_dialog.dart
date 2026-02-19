import 'package:flutter/material.dart';

import '../../domain/entities/production_event.dart';
import '../../domain/entities/production_session.dart';

/// Dialog pour reprendre une production après un événement.
/// Valide que les mêmes bobines sont toujours en place.
class ProductionResumeDialog extends StatelessWidget {
  const ProductionResumeDialog({
    super.key,
    required this.session,
    required this.onResumed,
  });

  final ProductionSession session;
  final ValueChanged<DateTime> onResumed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsNonTermines = session.events
        .where((e) => !e.estTermine)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Reprendre la production'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vérification des bobines',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les bobines doivent rester dans les machines. Vérifiez que toutes les bobines sont toujours en place avant de reprendre.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...session.bobinesUtilisees.map((bobine) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${bobine.bobineType} - ${bobine.machineName}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (bobine.estFinie)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                  ],
                ),
              );
            }),
            if (eventsNonTermines.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Événements en cours :',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...eventsNonTermines.map((event) {
                      final typeLabel = event.type == ProductionEventType.panne
                          ? 'Panne'
                          : event.type == ProductionEventType.coupure
                          ? 'Coupure'
                          : 'Arrêt forcé';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $typeLabel: ${event.motif}',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La reprise enregistrera l\'heure de reprise pour tous les événements en cours.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final now = DateTime.now();
            onResumed(now);
            Navigator.of(context).pop();
          },
          child: const Text('Reprendre'),
        ),
      ],
    );
  }
}

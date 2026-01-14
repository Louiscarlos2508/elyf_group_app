import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_event.dart';
import 'tracking_dialogs.dart';

/// Widget pour l'étape "Suspended" (suspendue) de la session de production.
class SuspendedStep extends ConsumerWidget {
  const SuspendedStep({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColors = Theme.of(context).extension<StatusColors>();

    return Card(
      color:
          statusColors?.danger.withValues(alpha: 0.1) ??
          Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  color: statusColors?.danger ?? Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Production suspendue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'La production a été suspendue (panne, coupure ou arrêt forcé).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Les bobines restent dans les machines et ne peuvent pas être retirées tant qu\'elles ne sont pas finies.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (session.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Événements enregistrés :',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...session.events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${event.type.label}: ${event.motif}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        TrackingDialogs.showEventDialog(context, ref, session),
                    icon: const Icon(Icons.warning),
                    label: const Text('Nouvel événement'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        TrackingDialogs.showResumeDialog(context, ref, session),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reprendre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => TrackingDialogs.showFinalizationDialog(
                      context,
                      ref,
                      session,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Finaliser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

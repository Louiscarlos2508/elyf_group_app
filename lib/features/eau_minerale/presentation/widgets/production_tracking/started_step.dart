import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_session.dart';
import 'info_row.dart';
import 'tracking_helpers.dart';
import 'tracking_actions.dart';
import 'tracking_dialogs.dart';

/// Widget pour l'étape "Started" (démarrée) de la session de production.
class StartedStep extends ConsumerWidget {
  const StartedStep({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Production démarrée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoRow(
              icon: Icons.access_time,
              label: 'Heure de début',
              value: TrackingHelpers.formatDateTime(session.heureDebut),
            ),
            const SizedBox(height: 24),
            Text(
              'Enregistrez les machines et bobines utilisées pour continuer.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TrackingActions(
              session: session,
              onAddMachine: () =>
                  TrackingDialogs.showAddMachineDialog(context, ref, session),
              onFinalize: () =>
                  TrackingDialogs.showFinalizationDialog(context, ref, session),
            ),
          ],
        ),
      ),
    );
  }
}

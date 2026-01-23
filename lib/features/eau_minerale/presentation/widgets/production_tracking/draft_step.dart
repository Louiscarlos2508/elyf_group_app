import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../../../shared/utils/notification_service.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';

/// Widget pour l'étape "Draft" (brouillon) de la session de production.
class DraftStep extends ConsumerWidget {
  const DraftStep({super.key, required this.session});

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
              onPressed: () => _startProduction(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer la production'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startProduction(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(productionSessionControllerProvider);
      
      // Mettre à jour la session avec l'heure de début actuelle et le statut "started"
      final now = DateTime.now();
      final updatedSession = session.copyWith(
        heureDebut: now,
        status: ProductionSessionStatus.started,
        updatedAt: now,
      );

      await controller.updateSession(updatedSession);

      // Invalider le provider pour rafraîchir l'UI
      ref.invalidate(productionSessionsStateProvider);
      ref.invalidate(productionSessionDetailProvider(session.id));

      if (context.mounted) {
        NotificationService.showSuccess(
          context,
          'Production démarrée avec succès',
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Erreur lors du démarrage: $e',
        );
      }
    }
  }
}

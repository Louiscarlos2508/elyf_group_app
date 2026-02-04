import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../screens/sections/production_session_detail_screen.dart';
import '../../screens/sections/production_tracking_screen.dart';
import 'production_sessions_card_components.dart';
import 'production_sessions_helpers.dart';

/// Carte affichant les informations d'une session de production.
class ProductionSessionsCard extends ConsumerWidget {
  const ProductionSessionsCard({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ventesAsync = ref.watch(ventesParSessionProvider((session.id)));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ProductionSessionDetailScreen(sessionId: session.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec Date et Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ProductionSessionsHelpers.formatDate(session.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ProductionSessionsHelpers.formatTime(session.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ProductionSessionsCardComponents.buildStatusChip(
                    context,
                    session.effectiveStatus,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Infos principales (Durée, Quantité)
              Row(
                children: [
                  _buildMetric(
                    context, 
                    Icons.access_time, 
                    '${session.dureeHeures.toStringAsFixed(1)} h',
                    'Durée',
                  ),
                  const SizedBox(width: 24),
                  _buildMetric(
                    context,
                    Icons.water_drop_outlined,
                    '${session.quantiteProduite.toInt()}',
                    'Produits',
                  ),
                ],
              ),

              const SizedBox(height: 16),
              
              // Indicateur de marge (si dispo)
              ventesAsync.when(
                data: (ventes) {
                  if (ventes.isEmpty) return const SizedBox.shrink();
                  // Version simplifiée de la marge pour la liste
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money, 
                          size: 16, 
                          color: theme.colorScheme.secondary
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ventes.length} Ventes enregistrées',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Bouton Suivre et Supprimer pour les sessions actives
              if (session.effectiveStatus != ProductionSessionStatus.completed)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductionTrackingScreen(
                                  sessionId: session.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_outlined, size: 20),
                          label: const Text('Suivre'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // Permettre la suppression si rien n'est renseigné dans le suivi
                      if (session.productionDays.isEmpty && session.events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton.outlined(
                            onPressed: () => _handleDelete(context, ref),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            style: IconButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(
                                color: theme.colorScheme.error.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            tooltip: 'Supprimer la session',
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action marquera la session comme annulée. '
              'Les bobines installées seront remises en stock.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif d\'annulation',
                hintText: 'Ex: Erreur de saisie, panne majeure...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await ref
            .read(productionSessionControllerProvider)
            .cancelSession(session, reasonController.text.trim());

        if (context.mounted) {
          ref.invalidate(productionSessionsStateProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session annulée avec succès.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'annulation : $e')),
          );
        }
      }
    }
  }

  Widget _buildMetric(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

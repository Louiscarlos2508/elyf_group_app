import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../screens/sections/production_session_detail_screen.dart';
import '../../screens/sections/production_tracking_screen.dart';
import 'production_sessions_helpers.dart';
import 'production_sessions_card_components.dart';

/// Carte affichant les informations d'une session de production.
class ProductionSessionsCard extends ConsumerWidget {
  const ProductionSessionsCard({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ElyfCard(
      isGlass: true,
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ProductionSessionDetailScreen(sessionId: session.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec Date et Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ProductionSessionsHelpers.formatDate(session.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ProductionSessionsHelpers.formatTime(session.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProductionSessionsCardComponents.buildStatusChip(
                  context,
                  session.effectiveStatus,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Infos principales (Durée, Quantité)
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    context, 
                    Icons.timer_outlined, 
                    '${session.dureeHeures.toStringAsFixed(1)} h',
                    'Durée',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetric(
                    context,
                    Icons.water_drop_outlined,
                    '${session.quantiteProduite.toInt()}',
                    'Produits',
                    Colors.cyan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            // Bouton Suivre et Supprimer pour les sessions actives
            if (session.effectiveStatus != ProductionSessionStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductionTrackingScreen(
                                sessionId: session.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 20),
                        label: const Text('Suivre la Session'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Permettre la suppression si rien n'est renseigné dans le suivi
                    if (session.productionDays.isEmpty && session.events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: IconButton.outlined(
                          onPressed: () => _handleDelete(context, ref),
                          icon: const Icon(Icons.delete_outline, size: 22),
                          style: IconButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(
                              color: theme.colorScheme.error.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          tooltip: 'Annuler la session',
                        ),
                      ),
                  ],
                ),
              ),
          ],
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
        content: SingleChildScrollView(
          child: Column(
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

  Widget _buildMetric(BuildContext context, IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

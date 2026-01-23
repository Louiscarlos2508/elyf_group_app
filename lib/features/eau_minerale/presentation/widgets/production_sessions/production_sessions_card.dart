import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../screens/sections/production_session_detail_screen.dart';
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
            ],
          ),
        ),
      ),
    );
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

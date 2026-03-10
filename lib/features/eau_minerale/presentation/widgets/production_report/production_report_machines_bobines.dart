import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/machine_material_usage.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import 'production_report_helpers.dart';

/// Section machines et bobines du rapport.
class ProductionReportMachinesBobines extends ConsumerWidget {
  const ProductionReportMachinesBobines({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allSessionsAsync = ref.watch(productionSessionsStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Machines et Matières',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nombre de machines: ${session.machinesUtilisees.length}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        allSessionsAsync.when(
          data: (allSessions) => _buildMaterialsList(theme, session, allSessions),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => _buildMaterialsListFallback(theme, session),
        ),
      ],
    );
  }

  Widget _buildMaterialsList(
    ThemeData theme,
    ProductionSession session,
    List<ProductionSession> allSessions,
  ) {
    return Column(
      children: session.machineMaterials.map((material) {
        final reuseInfo = _findMaterialReuseInfo(material, session, allSessions);
        final statutCloture =
            session.effectiveStatus == ProductionSessionStatus.completed
            ? (material.estFinie ? 'Finie' : 'Reste en machine')
            : null;

        return _MaterialCard(
          theme: theme,
          material: material,
          isReused: reuseInfo.isReused,
          sessionOrigine: reuseInfo.sessionOrigine,
          statutCloture: statutCloture,
        );
      }).toList(),
    );
  }

  Widget _buildMaterialsListFallback(ThemeData theme, ProductionSession session) {
    return Column(
      children: session.machineMaterials.map((material) {
        final statutCloture =
            session.effectiveStatus == ProductionSessionStatus.completed
            ? (material.estFinie ? 'Finie' : 'Reste en machine')
            : null;

        return _MaterialCard(
          theme: theme,
          material: material,
          isReused: false,
          sessionOrigine: null,
          statutCloture: statutCloture,
        );
      }).toList(),
    );
  }

  ({bool isReused, String? sessionOrigine}) _findMaterialReuseInfo(
    MachineMaterialUsage material,
    ProductionSession currentSession,
    List<ProductionSession> allSessions,
  ) {
    // Si la matière a été installée pendant cette session (après ou à l'heure du début), 
    // elle n'est pas réutilisée mais neuve.
    if (!material.heureInstallation.isBefore(currentSession.heureDebut)) {
      return (isReused: false, sessionOrigine: null);
    }

    final sessionsPrecedentes =
        allSessions
            .where(
              (s) =>
                  s.date.isBefore(currentSession.date) ||
                  (s.date.isAtSameMomentAs(currentSession.date) &&
                      s.id != currentSession.id),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    for (final s in sessionsPrecedentes) {
      try {
        final materialDansSessionPrecedente = s.machineMaterials.firstWhere(
          (m) => m.machineId == material.machineId && !m.estFinie,
        );

        if (materialDansSessionPrecedente.materialType == material.materialType) {
          return (
            isReused: true,
            sessionOrigine: ProductionReportHelpers.formatDate(s.date),
          );
        }
      } catch (_) {
        continue;
      }
    }

    return (isReused: false, sessionOrigine: null);
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.theme,
    required this.material,
    required this.isReused,
    this.sessionOrigine,
    this.statutCloture,
  });

  final ThemeData theme;
  final MachineMaterialUsage material;
  final bool isReused;
  final String? sessionOrigine;
  final String? statutCloture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: material.estFinie
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isReused
              ? Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  material.estFinie ? Icons.check_circle : Icons.rotate_right,
                  size: 20,
                  color: material.estFinie
                      ? Colors.green
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              material.materialType,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isReused)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Réutilisée',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Machine: ${material.machineName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isReused) ...[
                        const SizedBox(height: 4),
                        Text(
                          sessionOrigine != null
                              ? 'Matière non finie de la session du $sessionOrigine'
                              : 'Matière non finie d\'une session précédente',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (statutCloture != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: material.estFinie
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Statut à la clôture: $statutCloture',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: material.estFinie
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/bobine_usage.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session_status.dart';
import 'machine_breakdown_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Carte pour signaler une panne de machine dans les paramètres.
class MachineBreakdownReportCard extends ConsumerWidget {
  const MachineBreakdownReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final machinesAsync = ref.watch(allMachinesProvider);
    final sessionsAsync = ref.watch(productionSessionsStateProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_toggle_off_outlined,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signalement de Pannes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'En dehors des sessions actives',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            machinesAsync.when(
              data: (machines) {
                if (machines.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucune machine disponible',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return sessionsAsync.when(
                  data: (sessions) {
                    return Column(
                      children: machines.map((machine) {
                        // Trouver la bobine non finie pour cette machine (optionnel)
                        BobineUsage? bobineNonFinie;
                        ProductionSession? sessionActive;

                        for (final session in sessions) {
                          if (session.status ==
                                  ProductionSessionStatus.inProgress ||
                              session.status ==
                                  ProductionSessionStatus.started) {
                            final bobinesFiltrees = session.bobinesUtilisees
                                .where(
                                  (b) =>
                                      b.machineId == machine.id && !b.estFinie,
                                );
                            if (bobinesFiltrees.isNotEmpty) {
                              bobineNonFinie = bobinesFiltrees.first;
                              sessionActive = session;
                              break;
                            }
                          }
                        }

                        return _BreakdownMachineItem(
                          machine: machine,
                          bobine: bobineNonFinie,
                          onTap: () => _showBreakdownDialog(
                            context,
                            ref,
                            machine,
                            bobineNonFinie,
                            sessionActive,
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Erreur: ${error.toString()}'),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erreur: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    Machine machine,
    BobineUsage? bobine,
    ProductionSession? session,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => MachineBreakdownDialog(
        machine: machine,
        session: session,
        bobine: bobine,
        onPanneSignaled: (event) {
          ref.invalidate(productionSessionsStateProvider);
          if (session != null) {
            ref.invalidate(productionSessionDetailProvider((session.id)));
          }
          NotificationService.showInfo(context, 'Panne signalée avec succès');
        },
      ),
    );
  }
}

class _BreakdownMachineItem extends StatelessWidget {
  const _BreakdownMachineItem({
    required this.machine,
    this.bobine,
    required this.onTap,
  });

  final Machine machine;
  final BobineUsage? bobine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.precision_manufacturing_outlined,
            size: 20,
            color: bobine != null ? colors.error : colors.primary,
          ),
        ),
        title: Text(
          machine.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          bobine != null ? 'Bobine ${bobine!.bobineType} en cours' : 'Prête',
          style: theme.textTheme.bodySmall?.copyWith(
            color: bobine != null ? colors.error : colors.onSurfaceVariant,
            fontWeight: bobine != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

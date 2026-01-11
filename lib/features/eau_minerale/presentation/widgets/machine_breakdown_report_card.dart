import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build,
                  color: theme.colorScheme.error,
                  size: 24,
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
                      const SizedBox(height: 4),
                      Text(
                        'Signalez une panne de machine et retirez la bobine si nécessaire',
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
                          if (session.status == ProductionSessionStatus.inProgress ||
                              session.status == ProductionSessionStatus.started) {
                            final bobinesFiltrees = session.bobinesUtilisees.where(
                              (b) => b.machineId == machine.id && !b.estFinie,
                            );
                            if (bobinesFiltrees.isNotEmpty) {
                              bobineNonFinie = bobinesFiltrees.first;
                              sessionActive = session;
                              break;
                            }
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      radius: 20,
                                      child: Icon(
                                        Icons.precision_manufacturing,
                                        color: theme.colorScheme.onPrimaryContainer,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            machine.nom,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            bobineNonFinie != null
                                                ? 'Bobine ${bobineNonFinie.bobineType} en cours'
                                                : 'Aucune bobine en cours',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showBreakdownDialog(
                                      context,
                                      ref,
                                      machine,
                                      bobineNonFinie,
                                      sessionActive,
                                    ),
                                    icon: const Icon(Icons.build, size: 18),
                                    label: const Text('Signaler panne'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

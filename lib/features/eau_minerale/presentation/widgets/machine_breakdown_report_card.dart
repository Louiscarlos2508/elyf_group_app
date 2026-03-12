import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine_material_usage.dart';
import 'machine_breakdown_dialog.dart';
import 'machine_resume_dialog.dart';
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
                        // Trouver la matière non finie pour cette machine (optionnel)
                        MachineMaterialUsage? materialNonFinie;
                        ProductionSession? sessionActive;
 
                        for (final session in sessions) {
                          if (session.status ==
                                  ProductionSessionStatus.inProgress ||
                              session.status ==
                                  ProductionSessionStatus.started) {
                            final materialsFiltres = session.machineMaterials
                                .where(
                                  (b) =>
                                      b.machineId == machine.id && !b.estFinie,
                                );
                            if (materialsFiltres.isNotEmpty) {
                              materialNonFinie = materialsFiltres.first;
                              sessionActive = session;
                              break;
                            }
                          }
                        }

                        return _BreakdownMachineItem(
                          machine: machine,
                          material: materialNonFinie,
                          onTap: () {
                            if (machine.isActive) {
                              _showBreakdownDialog(
                                context,
                                ref,
                                machine,
                                materialNonFinie,
                                sessionActive,
                              );
                            } else {
                              _showResumeDialog(context, machine);
                            }
                          },
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
    MachineMaterialUsage? material,
    ProductionSession? session,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => MachineBreakdownDialog(
        machine: machine,
        session: session,
        material: material,
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

  void _showResumeDialog(BuildContext context, Machine machine) {
    showDialog(
      context: context,
      builder: (dialogContext) => MachineResumeDialog(machine: machine),
    );
  }
}

class _BreakdownMachineItem extends StatelessWidget {
  const _BreakdownMachineItem({
    required this.machine,
    this.material,
    required this.onTap,
  });

  final Machine machine;
  final MachineMaterialUsage? material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isBreakdown = !machine.isActive;
    
    // Status text and color logic
    String statusLabel = 'Prête';
    Color statusColor = colors.primary;
    IconData statusIcon = Icons.precision_manufacturing_outlined;
    
    if (isBreakdown) {
      statusLabel = 'EN PANNE';
      statusColor = colors.error;
      statusIcon = Icons.report_gmailerrorred_rounded;
    } else if (material != null) {
      statusLabel = 'En Production';
      statusColor = colors.secondary;
      statusIcon = Icons.settings_suggest_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            statusIcon,
            size: 20,
            color: statusColor,
          ),
        ),
        title: Text(
          machine.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isBreakdown ? colors.error : null,
          ),
        ),
        subtitle: Text(
          isBreakdown 
              ? 'Nécessite une remise en service' 
              : (material != null ? 'Matière ${material!.materialType} en cours' : 'Machine opérationnelle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor.withValues(alpha: 0.8),
            fontWeight: (isBreakdown || material != null) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
          ),
        ),
      ),
    );
  }
}

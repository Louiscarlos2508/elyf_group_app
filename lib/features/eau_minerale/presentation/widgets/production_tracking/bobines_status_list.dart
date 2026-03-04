import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/production_session.dart';
import '../../../application/providers.dart';
import 'tracking_dialogs.dart';

/// Widget pour afficher la liste des bobines avec leur statut.
class BobinesStatusList extends ConsumerWidget {
  const BobinesStatusList({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (session.bobinesUtilisees.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Grouper par machine
    final bobinesParMachine = <String, List<BobineUsage>>{};
    for (final bobine in session.bobinesUtilisees) {
      if (!bobinesParMachine.containsKey(bobine.machineName)) {
        bobinesParMachine[bobine.machineName] = [];
      }
      bobinesParMachine[bobine.machineName]!.add(bobine);
    }

    // 2. Récupérer le statut des machines pour bloquer l'installation si besoin
    final machinesAsync = ref.watch(allMachinesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État des bobines',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...bobinesParMachine.entries.map((entry) {
          final machineName = entry.key;
          final bobines = entry.value;
          
          // Identifier la machine pour connaître son statut isActive
          // On se base sur le machineId de la première bobine du groupe
          final machineId = bobines.first.machineId;
          final machine = machinesAsync.whenOrNull(
            data: (list) => list.where((m) => m.id == machineId).firstOrNull,
          );
          final isMachineActive = machine?.isActive ?? true; // Par défaut True si non chargé

          // Trouver la bobine active (non finie)
          final activeBobine = bobines.cast<BobineUsage?>().firstWhere(
                (b) => b != null && !b.estFinie,
                orElse: () => null,
              );
              
          final finishedBobines = bobines.where((b) => b.estFinie).toList();
          // Trier les finies par date (récent en premier)
          finishedBobines.sort((a, b) => b.heureInstallation.compareTo(a.heureInstallation));

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête Machine
                  Row(
                    children: [
                      Icon(
                        Icons.precision_manufacturing, 
                        size: 20, 
                        color: isMachineActive ? theme.colorScheme.primary : theme.colorScheme.error
                      ),
                      const SizedBox(width: 8),
                      Text(
                        machineName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isMachineActive ? null : theme.colorScheme.error,
                        ),
                      ),
                      if (!isMachineActive) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'EN PANNE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(),
                  
                  // Section Active ou Action
                  if (activeBobine != null)
                    _buildActiveBobineTile(context, ref, session, activeBobine, isMachineActive)
                  else if (!isMachineActive)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Installation impossible : Machine hors service',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                             final referenceBobine = bobines.first;
                             TrackingDialogs.showInstallNewBobineDialog(
                               context,
                               ref,
                               session,
                               referenceBobine,
                             );
                          },
                          icon: const Icon(Icons.add_circle, size: 18),
                          label: const Text('Installer une nouvelle bobine'),
                        ),
                      ),
                    ),

                  // Section Historique (si existant)
                  if (finishedBobines.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     Text(
                       'Historique',
                       style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                     ),
                     const SizedBox(height: 4),
                     ...finishedBobines.map((b) => _buildHistoryBobineTile(context, b)),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActiveBobineTile(BuildContext context, WidgetRef ref, ProductionSession session, BobineUsage bobine, bool isMachineActive) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: const Icon(Icons.sync, size: 20),
      ),
      title: Row(
        children: [
          Text(bobine.bobineType, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (bobine.isReused) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Text(
                'RÉUTILISÉE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: const Text('En cours d\'utilisation'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isMachineActive ? Icons.build : Icons.report_problem, 
              color: isMachineActive ? Colors.orange : Colors.grey, 
              size: 20
            ),
            tooltip: isMachineActive ? 'Signaler panne' : 'Machine déjà en panne',
            onPressed: isMachineActive 
                ? () => TrackingDialogs.showMachineBreakdownDialog(context, ref, session, bobine)
                : null,
          ),
          OutlinedButton.icon(
            onPressed: () => TrackingDialogs.showBobineFinishDialog(context, ref, session, bobine),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Finie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 48), // Override global infinite width
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBobineTile(BuildContext context, BobineUsage bobine) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            bobine.bobineType,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            'Terminée', 
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

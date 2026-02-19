import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/production_session.dart';
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
    // Note: On utilise machineName comme clé d'affichage facile
    for (final bobine in session.bobinesUtilisees) {
      if (!bobinesParMachine.containsKey(bobine.machineName)) {
        bobinesParMachine[bobine.machineName] = [];
      }
      bobinesParMachine[bobine.machineName]!.add(bobine);
    }

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
                      Icon(Icons.precision_manufacturing, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        machineName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Section Active ou Action
                  if (activeBobine != null)
                    _buildActiveBobineTile(context, ref, session, activeBobine)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                             // On a besoin d'une bobine de la machine pour connaitre l'ID de la machine
                             // Ici on prend la première de l'historique car elles sont groupées par machine
                             // C'est safe car la liste 'bobines' n'est pas vide (garanti par le groupement)
                             final referenceBobine = bobines.first;
                             TrackingDialogs.showInstallNewBobineDialog(
                               context,
                               ref,
                               session,
                               referenceBobine, // Sert juste à pré-remplir la machine
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

  Widget _buildActiveBobineTile(BuildContext context, WidgetRef ref, ProductionSession session, BobineUsage bobine) {
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
            icon: const Icon(Icons.build, color: Colors.orange, size: 20),
            tooltip: 'Signaler panne',
            onPressed: () => TrackingDialogs.showMachineBreakdownDialog(context, ref, session, bobine),
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

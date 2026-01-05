import 'package:flutter/material.dart';

import '../../../../domain/entities/bobine_usage.dart';
import 'production_session_form_helpers.dart';

/// Section pour l'installation des bobines sur les machines.
class BobinesInstallationSection extends StatelessWidget {
  const BobinesInstallationSection({
    super.key,
    required this.machinesSelectionnees,
    required this.bobinesUtilisees,
    required this.onInstallerBobine,
    required this.onSignalerPanne,
    required this.onRetirerBobine,
  });

  final List<String> machinesSelectionnees;
  final List<BobineUsage> bobinesUtilisees;
  final VoidCallback onInstallerBobine;
  final void Function(BuildContext, BobineUsage, int) onSignalerPanne;
  final ValueChanged<int> onRetirerBobine;

  @override
  Widget build(BuildContext context) {
    if (machinesSelectionnees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Sélectionnez d\'abord les machines dans l\'étape 1',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final machinesAvecBobine = bobinesUtilisees.map((b) => b.machineId).toSet();
    final machinesSansBobine = machinesSelectionnees
        .where((mId) => !machinesAvecBobine.contains(mId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bobines installées (${bobinesUtilisees.length}/${machinesSelectionnees.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (machinesSansBobine.isNotEmpty)
              IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: onInstallerBobine,
                  icon: const Icon(Icons.add),
                  label: const Text('Installer bobine'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (bobinesUtilisees.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajoutez ${machinesSelectionnees.length} bobine(s) (une par machine). Les bobines seront créées automatiquement.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          ...bobinesUtilisees.asMap().entries.map((entry) {
            final index = entry.key;
            final bobine = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text(bobine.bobineType),
                subtitle: Text(
                  'Machine: ${bobine.machineName}\n'
                  'Installée le: ${ProductionSessionFormHelpers.formatDate(bobine.dateInstallation)} à ${ProductionSessionFormHelpers.formatTime(bobine.heureInstallation)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.build, color: Colors.orange),
                      tooltip: 'Signaler panne',
                      onPressed: () => onSignalerPanne(context, bobine, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onRetirerBobine(index),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (bobinesUtilisees.length < machinesSelectionnees.length) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Il manque ${machinesSelectionnees.length - bobinesUtilisees.length} bobine(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


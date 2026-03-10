import 'package:flutter/material.dart';

import '../../../domain/entities/machine_material_usage.dart';
import 'production_session_form_helpers.dart';

/// Section pour l'installation des matières sur les machines.
/// (Anciennement BobinesInstallationSection).
class MachineMaterialsInstallationSection extends StatelessWidget {
  const MachineMaterialsInstallationSection({
    super.key,
    required this.machinesSelectionnees,
    required this.materials,
    required this.onInstallerMatiere,
    required this.onSignalerPanne,
    required this.onRetirerMatiere,
  });

  final List<String> machinesSelectionnees;
  final List<MachineMaterialUsage> materials;
  final VoidCallback onInstallerMatiere;
  final void Function(BuildContext, MachineMaterialUsage, int) onSignalerPanne;
  final ValueChanged<int> onRetirerMatiere;

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

    final machinesAvecMatiere = materials.map((b) => b.machineId).toSet();
    final machinesSansMatiere = machinesSelectionnees
        .where((mId) => !machinesAvecMatiere.contains(mId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Matières installées (${materials.length}/${machinesSelectionnees.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (machinesSansMatiere.isNotEmpty)
              IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: onInstallerMatiere,
                  icon: const Icon(Icons.add),
                  label: const Text('Installer matière'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (materials.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajoutez ${machinesSelectionnees.length} matière(s) (une par machine).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...materials.asMap().entries.map((entry) {
            final index = entry.key;
            final material = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text(material.materialType),
                subtitle: Text(
                  'Machine: ${material.machineName}\n'
                  'Installée le: ${ProductionSessionFormHelpers.formatDate(material.dateInstallation)} à ${ProductionSessionFormHelpers.formatTime(material.heureInstallation)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.build, color: Colors.orange),
                      tooltip: 'Signaler panne',
                      onPressed: () => onSignalerPanne(context, material, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onRetirerMatiere(index),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (materials.length < machinesSelectionnees.length) ...[
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
                    'Il manque ${machinesSelectionnees.length - materials.length} matière(s)',
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

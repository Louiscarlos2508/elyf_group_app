import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine.dart';

/// Champ pour sélectionner les machines utilisées.
class MachineSelectorField extends ConsumerWidget {
  const MachineSelectorField({
    super.key,
    required this.machinesSelectionnees,
    required this.onMachinesChanged,
  });

  final List<String> machinesSelectionnees;
  final ValueChanged<List<String>> onMachinesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesAsync = ref.watch(machinesProvider);

    return machinesAsync.when(
      data: (machines) {
        final machinesActives = machines.where((m) => m.estActive).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Machines utilisées',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (machinesActives.isEmpty)
              const Text('Aucune machine active disponible')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: machinesActives.map((machine) {
                  final estSelectionnee = machinesSelectionnees.contains(
                    machine.id,
                  );
                  return FilterChip(
                    label: Text(machine.nom),
                    selected: estSelectionnee,
                    onSelected: (selected) {
                      final nouvellesMachines = List<String>.from(
                        machinesSelectionnees,
                      );
                      if (selected) {
                        if (!nouvellesMachines.contains(machine.id)) {
                          nouvellesMachines.add(machine.id);
                        }
                      } else {
                        nouvellesMachines.remove(machine.id);
                      }
                      onMachinesChanged(nouvellesMachines);
                    },
                  );
                }).toList(),
              ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }
}

/// Provider pour récupérer les machines.
final machinesProvider = FutureProvider.autoDispose<List<Machine>>((ref) async {
  return ref.read(machineControllerProvider).fetchMachines(estActive: true);
});

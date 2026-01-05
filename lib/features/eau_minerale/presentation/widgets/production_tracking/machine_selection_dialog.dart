import 'package:flutter/material.dart';

import '../../../../domain/entities/machine.dart';

/// Dialog pour sélectionner une machine parmi les machines disponibles.
class MachineSelectionDialog {
  /// Affiche le dialog de sélection de machine.
  static Future<Machine?> show(
    BuildContext context,
    List<Machine> machinesDisponibles,
  ) async {
    if (machinesDisponibles.isEmpty) {
      return null;
    }

    if (machinesDisponibles.length == 1) {
      return machinesDisponibles.first;
    }

    return await showDialog<Machine>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sélectionner une machine'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: machinesDisponibles.length,
            itemBuilder: (context, index) {
              final machine = machinesDisponibles[index];
              return ListTile(
                title: Text(machine.nom),
                onTap: () => Navigator.of(context).pop(machine),
              );
            },
          ),
        ),
      ),
    );
  }
}


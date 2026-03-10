import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/machine_material_usage.dart';
import '../machine_material_installation_form.dart';
import 'machine_add_helpers.dart';

/// Dialog pour installer une bobine sur une machine.
class MachineInstallationFormDialog {
  /// Affiche le dialog d'installation de bobine.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    Machine machine,
    void Function()? onSuccess,
  ) async {
    await showDialog<MachineMaterialUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: MachineMaterialInstallationForm(
            machine: machine,
            onInstalled: (newMaterial) async {
              await MachineAddHelpers.addMachineWithMaterial(
                context,
                ref,
                session,
                machine,
                newMaterial,
              );

              if (context.mounted) {
                onSuccess?.call();
              }
            },
          ),
        ),
      ),
    );
  }
}

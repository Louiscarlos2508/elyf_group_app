import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_session.dart';
import '../bobine_installation_form.dart';
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
    await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: BobineInstallationForm(
            machine: machine,
            onInstalled: (newBobine) async {
              await MachineAddHelpers.addMachineWithBobine(
                context,
                ref,
                session,
                machine,
                newBobine,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                onSuccess?.call();
              }
            },
          ),
        ),
      ),
    );
  }
}

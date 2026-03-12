import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/machine_material_usage.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../machine_material_finish_dialog.dart';
import '../machine_breakdown_dialog.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Dialogs pour la gestion des matières machine.
/// (Anciennement BobineDialogs).
class MachineMaterialTrackingDialogs {
  /// Affiche le dialog pour signaler une panne de machine.
  static void showMachineBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage material,
  ) async {
    final machineController = ref.read(machineControllerProvider);
    final machine = await machineController.fetchMachineById(material.machineId);

    if (machine == null) {
      if (context.mounted) {
        NotificationService.showError(context, 'Impossible de trouver les détails de la machine ${material.machineId}.');
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => MachineBreakdownDialog(
          machine: machine,
          session: session,
          material: material,
          onPanneSignaled: (event) {
            ref.invalidate(productionSessionDetailProvider((session.id)));
          },
        ),
      );
    }
  }

  /// Affiche le dialog pour marquer une matière comme finie.
  static void showMaterialFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage material,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => MachineMaterialFinishDialog(
        session: session,
        material: material,
        onFinished: (updatedSession) {
          ref.invalidate(productionSessionDetailProvider((session.id)));
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../bobine_finish_dialog.dart';
import '../machine_breakdown_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Dialogs pour la gestion des bobines.
class BobineDialogs {
  /// Affiche le dialog pour signaler une panne de machine.
  static void showMachineBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage bobine,
  ) async {
    // 1. Récupérer l'objet machine complet pour éviter la perte d'attributs lors de l'update
    final machineController = ref.read(machineControllerProvider);
    final machine = await machineController.fetchMachineById(bobine.machineId);

    if (machine == null) {
      if (context.mounted) {
        NotificationService.showError(context, 'Impossible de trouver les détails de la machine ${bobine.machineId}.');
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => MachineBreakdownDialog(
          machine: machine,
          session: session,
          bobine: bobine,
          onPanneSignaled: (event) {
            ref.invalidate(productionSessionDetailProvider((session.id)));
            // Optionnel: NotificationService.showInfo est dejà géré par le dialog
          },
        ),
      );
    }
  }

  /// Affiche le dialog pour marquer une bobine comme finie.
  static void showBobineFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage bobine,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => BobineFinishDialog(
        session: session,
        bobine: bobine,
        onFinished: (updatedSession) {
          ref.invalidate(productionSessionDetailProvider((session.id)));
        },
      ),
    );
  }
}

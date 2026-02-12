import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
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
  ) {
    final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
    final machine = Machine(
      id: bobine.machineId,
      name: bobine.machineName,
      enterpriseId: enterpriseId,
      reference: bobine.machineId,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => MachineBreakdownDialog(
        machine: machine,
        session: session,
        bobine: bobine,
        onPanneSignaled: (event) {
          ref.invalidate(productionSessionDetailProvider((session.id)));
          NotificationService.showInfo(context, 'Panne signalée avec succès');
        },
      ),
    );
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

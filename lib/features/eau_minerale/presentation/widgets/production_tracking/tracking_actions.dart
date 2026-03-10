import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/machine_material_usage.dart';
import '../../../domain/entities/production_session.dart';
import 'tracking_dialogs.dart';

/// Widget pour les actions de suivi de production.
class TrackingActions extends StatelessWidget {
  const TrackingActions({
    super.key,
    required this.session,
    required this.onAddMachine,
    required this.onFinalize,
  });

  final ProductionSession session;
  final VoidCallback onAddMachine;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: onAddMachine,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une machine'),
        ),
        if (session.machinesUtilisees.isNotEmpty &&
            session.machineMaterials.isNotEmpty) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onFinalize,
            icon: const Icon(Icons.check),
            label: const Text('Finaliser la production'),
          ),
        ],
      ],
    );
  }

  /// Affiche le dialog pour ajouter une machine.
  static Future<void> showAddMachineDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) async {
    return TrackingDialogs.showAddMachineDialog(context, ref, session);
  }

  /// Affiche le dialog de finalisation.
  static void showFinalizationDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    TrackingDialogs.showFinalizationDialog(context, ref, session);
  }

  /// Affiche le dialog pour installer une nouvelle bobine.
  static Future<void> showInstallNewMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage oldMaterial,
  ) async {
    return TrackingDialogs.showInstallNewMaterialDialog(
      context,
      ref,
      session,
      oldMaterial,
    );
  }

  /// Affiche le dialog pour signaler une panne de machine.
  static void showMachineBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage material,
  ) {
    TrackingDialogs.showMachineBreakdownDialog(context, ref, session, material);
  }

  /// Affiche le dialog pour marquer une bobine comme finie.
  static void showMaterialFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage material,
  ) {
    TrackingDialogs.showMaterialFinishDialog(context, ref, session, material);
  }

  /// Affiche le dialog pour enregistrer un événement.
  static void showEventDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    TrackingDialogs.showEventDialog(context, ref, session);
  }

  /// Affiche le dialog pour reprendre la production.
  static void showResumeDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    TrackingDialogs.showResumeDialog(context, ref, session);
  }
}

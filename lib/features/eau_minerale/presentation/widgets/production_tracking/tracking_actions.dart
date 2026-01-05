import 'package:flutter/material.dart';

import '../../../../domain/entities/production_session.dart';
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
            session.bobinesUtilisees.isNotEmpty) ...[
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
  static Future<void> showInstallNewBobineDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage oldBobine,
  ) async {
    return TrackingDialogs.showInstallNewBobineDialog(
      context,
      ref,
      session,
      oldBobine,
    );
  }

  /// Affiche le dialog pour signaler une panne de machine.
  static void showMachineBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage bobine,
  ) {
    TrackingDialogs.showMachineBreakdownDialog(context, ref, session, bobine);
  }

  /// Affiche le dialog pour marquer une bobine comme finie.
  static void showBobineFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage bobine,
  ) {
    TrackingDialogs.showBobineFinishDialog(context, ref, session, bobine);
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


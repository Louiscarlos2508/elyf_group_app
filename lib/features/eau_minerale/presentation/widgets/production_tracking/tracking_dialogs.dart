import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/machine_material_usage.dart';
import '../../../domain/entities/production_session.dart';
import 'machine_material_tracking_dialogs.dart';
import 'machine_dialogs.dart';
import 'session_dialogs.dart';

/// Dialogs pour les actions de suivi de production.
///
/// Cette classe délègue aux classes spécialisées :
/// - [MachineDialogs] pour les dialogs liés aux machines
/// - [MachineMaterialTrackingDialogs] pour les dialogs liés aux matières machine
/// - [SessionDialogs] pour les dialogs liés à la session
class TrackingDialogs {
  /// Affiche le dialog pour ajouter une machine.
  static Future<void> showAddMachineDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) async {
    return MachineDialogs.showAddMachineDialog(context, ref, session);
  }

  /// Affiche le dialog pour installer une nouvelle matière machine.
  static Future<void> showInstallNewMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage oldMaterial,
  ) async {
    return MachineDialogs.showInstallNewMaterialDialog(
      context,
      ref,
      session,
      oldMaterial,
    );
  }

  /// Affiche le dialog de finalisation.
  static void showFinalizationDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    SessionDialogs.showFinalizationDialog(context, ref, session);
  }

  /// Affiche le dialog pour signaler une panne de machine.
  static void showMachineBreakdownDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage material,
  ) {
    MachineMaterialTrackingDialogs.showMachineBreakdownDialog(context, ref, session, material);
  }

  /// Affiche le dialog pour marquer une matière machine comme finie.
  static void showMaterialFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage material,
  ) {
    MachineMaterialTrackingDialogs.showMaterialFinishDialog(context, ref, session, material);
  }

  /// Affiche le dialog pour enregistrer un événement.
  static void showEventDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    SessionDialogs.showEventDialog(context, ref, session);
  }

  static void showResumeDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    SessionDialogs.showResumeDialog(context, ref, session);
  }
}

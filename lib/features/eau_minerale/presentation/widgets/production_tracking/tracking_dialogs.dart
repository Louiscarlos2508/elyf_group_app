import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/bobine_usage.dart';
import '../../../../domain/entities/production_session.dart';
import 'bobine_dialogs.dart';
import 'machine_dialogs.dart';
import 'session_dialogs.dart';

/// Dialogs pour les actions de suivi de production.
/// 
/// Cette classe délègue aux classes spécialisées :
/// - [MachineDialogs] pour les dialogs liés aux machines
/// - [BobineDialogs] pour les dialogs liés aux bobines
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

  /// Affiche le dialog pour installer une nouvelle bobine.
  static Future<void> showInstallNewBobineDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage oldBobine,
  ) async {
    return MachineDialogs.showInstallNewBobineDialog(
      context,
      ref,
      session,
      oldBobine,
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
    BobineUsage bobine,
  ) {
    BobineDialogs.showMachineBreakdownDialog(context, ref, session, bobine);
  }

  /// Affiche le dialog pour marquer une bobine comme finie.
  static void showBobineFinishDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage bobine,
  ) {
    BobineDialogs.showBobineFinishDialog(context, ref, session, bobine);
  }

  /// Affiche le dialog pour enregistrer un événement.
  static void showEventDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    SessionDialogs.showEventDialog(context, ref, session);
  }

  /// Affiche le dialog pour reprendre la production.
  static void showResumeDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    SessionDialogs.showResumeDialog(context, ref, session);
  }
}


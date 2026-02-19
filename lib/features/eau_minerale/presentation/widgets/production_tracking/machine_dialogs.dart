import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/bobine_usage.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../bobine_installation_form.dart';
import 'machine_add_helpers.dart';
import 'machine_installation_form_dialog.dart';
import 'machine_selection_dialog.dart';

/// Dialogs pour la gestion des machines.
class MachineDialogs {
  /// Affiche le dialog pour ajouter une machine.
  static Future<void> showAddMachineDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<Machine> allMachines;
    try {
      allMachines = await ref.read(allMachinesProvider.future);
    } catch (e, _) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        NotificationService.showInfo(
          context,
          'Erreur lors du chargement des machines: $e',
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final machinesUtiliseesIds = session.machinesUtilisees.toSet();
    final machinesActives =
        allMachines.where((m) => m.isActive).toList();
    final machinesDisponibles = machinesActives
        .where((m) => !machinesUtiliseesIds.contains(m.id))
        .toList();

    if (machinesDisponibles.isEmpty) {
      if (context.mounted) {
        final message = machinesActives.isEmpty
            ? 'Aucune machine active configurée. Ajoutez-en dans les paramètres.'
            : 'Toutes les machines actives sont déjà utilisées dans cette session.';
        NotificationService.showWarning(context, message);
      }
      return;
    }

    if (!context.mounted) return;

    final machineSelectionnee = await MachineSelectionDialog.show(
      context,
      machinesDisponibles,
    );

    if (machineSelectionnee == null || !context.mounted) return;

    final bobineNonFinieExistante =
        await MachineAddHelpers.findUnfinishedBobine(
          ref,
          machineSelectionnee.id,
        );

    if (!context.mounted) return;

    if (bobineNonFinieExistante != null) {
      await MachineAddHelpers.reuseUnfinishedBobine(
        context,
        ref,
        session,
        machineSelectionnee,
        bobineNonFinieExistante,
      );
      return;
    }

    if (!context.mounted) return;

    await MachineInstallationFormDialog.show(
      context,
      ref,
      session,
      machineSelectionnee,
      null,
    );
  }

  /// Affiche le dialog pour installer une nouvelle bobine.
  static Future<void> showInstallNewBobineDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    BobineUsage oldBobine,
  ) async {
    final machines = await ref.read(allMachinesProvider.future);

    if (!context.mounted) return;

    final machine = machines.firstWhere(
      (m) => m.id == oldBobine.machineId,
      orElse: () => throw StateError('Machine not found'),
    );

    if (!context.mounted) return;

    await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: BobineInstallationForm(
            machine: machine,
            onInstalled: (newBobine) async {
              final aBobineActive = session.bobinesUtilisees.any(
                (b) => b.machineId == newBobine.machineId && !b.estFinie,
              );

              if (aBobineActive) {
                if (context.mounted) {
                  NotificationService.showWarning(
                    context,
                    'Cette machine a déjà une bobine active. Finalisez d\'abord la bobine en cours.',
                  );
                }
                return;
              }

              final updatedBobines = List<BobineUsage>.from(
                session.bobinesUtilisees,
              );

              // 1. Marquer la bobine précédente comme finie
              final indexOld = updatedBobines.indexWhere(
                (b) =>
                    b.machineId == oldBobine.machineId &&
                    b.bobineType == oldBobine.bobineType &&
                    !b.estFinie,
              );

              if (indexOld != -1) {
                updatedBobines[indexOld] = updatedBobines[indexOld].copyWith(
                  estFinie: true,
                  dateUtilisation: DateTime.now(), // Date de fin = maintenant
                );
              }

              // 2. Ajouter la nouvelle bobine
              // Vérifier doublon (au cas où)
              final existeDeja = updatedBobines.any(
                (b) =>
                    b.bobineType == newBobine.bobineType &&
                    b.machineId == newBobine.machineId &&
                    !b.estFinie &&
                    b != updatedBobines[indexOld], // Différent de celle qu'on vient de finir
              );

              if (!existeDeja) {
                updatedBobines.add(newBobine);
              }

              final updatedSession = session.copyWith(
                bobinesUtilisees: updatedBobines,
              );

              final controller = ref.read(productionSessionControllerProvider);
              await controller.updateSession(updatedSession);

              if (context.mounted) {
                ref.invalidate(productionSessionDetailProvider((session.id)));
                ref.invalidate(productionSessionsStateProvider);
                NotificationService.showSuccess(
                  context,
                  'Nouvelle bobine installée avec succès',
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

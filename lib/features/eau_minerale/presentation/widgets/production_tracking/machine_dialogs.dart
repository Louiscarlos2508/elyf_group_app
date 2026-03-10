import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../machine_material_installation_form.dart';
import 'machine_add_helpers.dart';
import 'machine_installation_form_dialog.dart';
import 'machine_selection_dialog.dart';
import '../../../domain/entities/machine_material_usage.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/machine.dart';

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

    // Rechercher une matière non finie (anciennement bobine)
    final matiereNonFinieExistante =
        await MachineAddHelpers.findUnfinishedMaterial(
          ref,
          machineSelectionnee.id,
        );

    if (!context.mounted) return;

    if (matiereNonFinieExistante != null) {
      await MachineAddHelpers.reuseUnfinishedMaterial(
        context,
        ref,
        session,
        machineSelectionnee,
        matiereNonFinieExistante, 
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

  /// Affiche le dialog pour installer une nouvelle matière (anciennement bobine).
  static Future<void> showInstallNewMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    MachineMaterialUsage oldMaterial,
  ) async {
    final machines = await ref.read(allMachinesProvider.future);

    if (!context.mounted) return;

    final machine = machines.firstWhere(
      (m) => m.id == oldMaterial.machineId,
      orElse: () => throw StateError('Machine not found'),
    );

    if (!context.mounted) return;

    await showDialog<MachineMaterialUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: MachineMaterialInstallationForm(
            machine: machine,
            onInstalled: (newMaterial) async {
              final aMatiereActive = session.machineMaterials.any(
                (m) => m.machineId == newMaterial.machineId && !m.estFinie,
              );

              if (aMatiereActive) {
                if (context.mounted) {
                  NotificationService.showWarning(
                    context,
                    'Cette machine a déjà une matière active. Finalisez d\'abord la matière en cours.',
                  );
                }
                return;
              }

              final updatedMaterials = List<MachineMaterialUsage>.from(
                session.machineMaterials,
              );

              // 1. Marquer la matière précédente comme finie
              final indexOld = updatedMaterials.indexWhere(
                (m) =>
                    m.machineId == oldMaterial.machineId &&
                    m.materialType == oldMaterial.materialType &&
                    !m.estFinie,
              );

              if (indexOld != -1) {
                updatedMaterials[indexOld] = updatedMaterials[indexOld].copyWith(
                  estFinie: true,
                  dateUtilisation: DateTime.now(),
                );
              }

              // 2. Ajouter la nouvelle matière
              final existeDeja = updatedMaterials.any(
                (m) =>
                    m.materialType == newMaterial.materialType &&
                    m.machineId == newMaterial.machineId &&
                    !m.estFinie &&
                    m != (indexOld != -1 ? updatedMaterials[indexOld] : null),
              );

              if (!existeDeja) {
                updatedMaterials.add(newMaterial);
              }

              final updatedSession = session.copyWith(
                machineMaterials: updatedMaterials,
              );

              final controller = ref.read(productionSessionControllerProvider);
              await controller.updateSession(updatedSession);

              if (context.mounted) {
                ref.invalidate(productionSessionDetailProvider((session.id)));
                ref.invalidate(productionSessionsStateProvider);
                NotificationService.showSuccess(
                  context,
                  'Nouvelle matière installée avec succès',
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

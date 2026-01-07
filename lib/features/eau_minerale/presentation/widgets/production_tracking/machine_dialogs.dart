import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_session.dart';
import '../../../application/providers.dart';
import '../../screens/sections/production_session_detail_screen.dart' show productionSessionDetailProvider;
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
    final machinesAsync = ref.watch(allMachinesProvider);

    await machinesAsync.when(
      data: (allMachines) async {
        final machinesUtiliseesIds = session.machinesUtilisees.toSet();
        final machinesDisponibles = allMachines.where(
          (m) => m.estActive && !machinesUtiliseesIds.contains(m.id),
        ).toList();

        if (machinesDisponibles.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Toutes les machines actives sont déjà utilisées'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (!context.mounted) return;

        final machineSelectionnee = await MachineSelectionDialog.show(
          context,
          machinesDisponibles,
        );

        if (machineSelectionnee == null || !context.mounted) return;

        final bobineNonFinieExistante = await MachineAddHelpers.findUnfinishedBobine(
          ref,
          machineSelectionnee.id,
        );

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

        await MachineInstallationFormDialog.show(
          context,
          ref,
          session,
          machineSelectionnee,
          null,
        );
      },
      loading: () {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
      error: (error, stack) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des machines: $error'),
            ),
          );
        }
      },
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: BobineInstallationForm(
            machine: machine,
            onInstalled: (newBobine) async {
              final aBobineActive = session.bobinesUtilisees.any(
                (b) => b.machineId == newBobine.machineId && !b.estFinie,
              );

              if (aBobineActive) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cette machine a déjà une bobine active. Finalisez d\'abord la bobine en cours.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              final updatedBobines = List<BobineUsage>.from(session.bobinesUtilisees);

              final existeDeja = updatedBobines.any(
                (b) =>
                    b.bobineType == newBobine.bobineType &&
                    b.machineId == newBobine.machineId &&
                    !b.estFinie,
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
                ref.invalidate(productionSessionDetailProvider(session.id));
                ref.invalidate(productionSessionsStateProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nouvelle bobine installée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}


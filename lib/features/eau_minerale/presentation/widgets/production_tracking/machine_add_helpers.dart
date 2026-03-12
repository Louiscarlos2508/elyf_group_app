import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/machine_material_usage.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Helpers pour l'ajout de machines.
class MachineAddHelpers {
  /// Recherche une matière non finie existante pour une machine donnée.
  static Future<MachineMaterialUsage?> findUnfinishedMaterial(
    WidgetRef ref,
    String machineId,
  ) async {
    for (final session in await ref.read(
      productionSessionsStateProvider.future,
    )) {
      for (final material in session.machineMaterials) {
        if (!material.estFinie && material.machineId == machineId) {
          return material;
        }
      }
    }
    return null;
  }

  /// Réutilise une matière non finie existante.
  static Future<void> reuseUnfinishedMaterial(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    Machine machine,
    MachineMaterialUsage materialNonFinie,
  ) async {
    final maintenant = DateTime.now();
    final materialReutilise = materialNonFinie.copyWith(
      dateInstallation: maintenant,
      heureInstallation: maintenant,
    );

    final updatedMachines = List<String>.from(session.machinesUtilisees);
    if (!updatedMachines.contains(machine.id)) {
      updatedMachines.add(machine.id);
    }
    final updatedMaterials = List<MachineMaterialUsage>.from(session.machineMaterials)
      ..add(materialReutilise);

    final updatedSession = session.copyWith(
      machinesUtilisees: updatedMachines,
      machineMaterials: updatedMaterials,
    );

    final controller = ref.read(productionSessionControllerProvider);
    await controller.updateSession(updatedSession);

    if (context.mounted) {
      ref.invalidate(productionSessionDetailProvider((session.id)));
      NotificationService.showSuccess(
        context,
        'Machine ${machine.name} ajoutée. Matière non finie réutilisée: ${materialNonFinie.materialType}',
      );
    }
  }

  /// Ajoute une machine avec une nouvelle matière installée.
  static Future<void> addMachineWithMaterial(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    Machine machine,
    MachineMaterialUsage newMaterial,
  ) async {
    final updatedMachines = List<String>.from(session.machinesUtilisees);
    if (!updatedMachines.contains(machine.id)) {
      updatedMachines.add(machine.id);
    }
    final updatedMaterials = List<MachineMaterialUsage>.from(session.machineMaterials)
      ..add(newMaterial);

    final updatedSession = session.copyWith(
      machinesUtilisees: updatedMachines,
      machineMaterials: updatedMaterials,
    );

    final controller = ref.read(productionSessionControllerProvider);
    await controller.updateSession(updatedSession);

    if (context.mounted) {
      ref.invalidate(productionSessionDetailProvider((session.id)));
      NotificationService.showSuccess(
        context,
        'Machine ${machine.name} ajoutée avec succès',
      );
    }
  }
}

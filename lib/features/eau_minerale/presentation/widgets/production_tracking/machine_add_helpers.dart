import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../screens/sections/production_session_detail_screen.dart' show productionSessionDetailProvider;
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
/// Helpers pour l'ajout de machines.
class MachineAddHelpers {
  /// Recherche une bobine non finie existante pour une machine donnée.
  static Future<BobineUsage?> findUnfinishedBobine(
    WidgetRef ref,
    String machineId,
  ) async {
    for (final session in await ref.read(productionSessionsStateProvider.future)) {
      for (final bobine in session.bobinesUtilisees) {
        if (!bobine.estFinie && bobine.machineId == machineId) {
          return bobine;
        }
      }
    }
    return null;
  }

  /// Réutilise une bobine non finie existante.
  static Future<void> reuseUnfinishedBobine(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    Machine machine,
    BobineUsage bobineNonFinie,
  ) async {
    final maintenant = DateTime.now();
    final bobineReutilisee = bobineNonFinie.copyWith(
      dateInstallation: maintenant,
      heureInstallation: maintenant,
    );

    final updatedMachines = List<String>.from(session.machinesUtilisees)
      ..add(machine.id);
    final updatedBobines = List<BobineUsage>.from(session.bobinesUtilisees)
      ..add(bobineReutilisee);

    final updatedSession = session.copyWith(
      machinesUtilisees: updatedMachines,
      bobinesUtilisees: updatedBobines,
    );

    final controller = ref.read(productionSessionControllerProvider);
    await controller.updateSession(updatedSession);

    if (context.mounted) {
      ref.invalidate(productionSessionDetailProvider((session.id)));
      NotificationService.showSuccess(context, 
            'Machine ${machine.nom} ajoutée. Bobine non finie réutilisée: ${bobineNonFinie.bobineType}',
          );
    }
  }

  /// Ajoute une machine avec une nouvelle bobine installée.
  static Future<void> addMachineWithBobine(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
    Machine machine,
    BobineUsage newBobine,
  ) async {
    final updatedMachines = List<String>.from(session.machinesUtilisees)
      ..add(machine.id);
    final updatedBobines = List<BobineUsage>.from(session.bobinesUtilisees)
      ..add(newBobine);

    final updatedSession = session.copyWith(
      machinesUtilisees: updatedMachines,
      bobinesUtilisees: updatedBobines,
    );

    final controller = ref.read(productionSessionControllerProvider);
    await controller.updateSession(updatedSession);

    if (context.mounted) {
      ref.invalidate(productionSessionDetailProvider((session.id)));
      NotificationService.showSuccess(context, 
            'Machine ${machine.nom} ajoutée avec succès',
          );
    }
  }
}


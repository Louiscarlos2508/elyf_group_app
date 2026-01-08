import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../widgets/bobine_installation_form.dart';
import '../../widgets/daily_personnel_form.dart';
import '../../widgets/machine_breakdown_dialog.dart';
import '../../widgets/machine_selector_field.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
/// Helper class for production session form dialogs.
/// Extracted from ProductionSessionFormSteps to reduce file size.
class ProductionSessionFormDialogs {
  /// Show bobine installation dialog.
  static Future<void> showBobineInstallation({
    required BuildContext context,
    required WidgetRef ref,
    required List<String> machinesSelectionnees,
    required List<BobineUsage> bobinesUtilisees,
    required Function(List<BobineUsage>) onBobinesChanged,
  }) async {
    // Trouver une machine sans bobine
    final machinesAvecBobine = bobinesUtilisees.map((b) => b.machineId).toSet();
    final machinesSansBobine = machinesSelectionnees
        .where((mId) => !machinesAvecBobine.contains(mId))
        .toList();

    if (machinesSansBobine.isEmpty) {
      NotificationService.showInfo(context, 'Toutes les machines ont une bobine');
      return;
    }

    // Récupérer les machines
    final machines = await ref.read(machinesProvider.future);
    final machine = machines.firstWhere((m) => m.id == machinesSansBobine.first);

    if (!context.mounted) return;
    final result = await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: BobineInstallationForm(
          machine: machine,
          // Le formulaire vérifiera automatiquement s'il y a une bobine non finie à réutiliser
        ),
      ),
    );

    if (result != null && context.mounted) {
      // Vérifier si cette bobine n'est pas déjà dans la liste (cas de réutilisation)
      final existeDeja = bobinesUtilisees.any(
        (b) => b.bobineType == result.bobineType && b.machineId == result.machineId,
      );
      
      if (!existeDeja) {
        // Le stock est déjà décrémenté dans BobineInstallationForm pour les nouvelles bobines
        // Les bobines non finie réutilisées n'ont pas besoin de décrément
        final updatedBobines = List<BobineUsage>.from(bobinesUtilisees)..add(result);
        onBobinesChanged(updatedBobines);
      }
    }
  }

  /// Show personnel form dialog.
  static Future<void> showPersonnelForm({
    required BuildContext context,
    required WidgetRef ref,
    required ProductionSession? session,
    required DateTime selectedDate,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
    required List<ProductionDay> productionDays,
    required DateTime date,
    required Function(ProductionDay) onDayAdded,
    required Function(ProductionDay) onDayUpdated,
  }) async {
    // Créer une session temporaire pour le formulaire
    final tempSession = ProductionSession(
      id: session?.id ?? 'temp',
      date: selectedDate,
      period: 1,
      heureDebut: heureDebut,
      consommationCourant: 0,
      machinesUtilisees: machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees,
      quantiteProduite: 0,
      quantiteProduiteUnite: 'pack',
      productionDays: productionDays,
    );

    // Vérifier si un jour existe déjà pour cette date
    ProductionDay? existingDay;
    try {
      existingDay = productionDays.firstWhere(
        (d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
      );
    } catch (e) {
      existingDay = null;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: DailyPersonnelForm(
            session: tempSession,
            date: date,
            existingDay: existingDay,
            onSaved: (productionDay) {
              if (existingDay != null) {
                onDayUpdated(productionDay);
              } else {
                onDayAdded(productionDay);
              }
              
              // IMPORTANT: Ne pas mettre à jour les stocks ici
              // Les mouvements de stock seront enregistrés UNIQUEMENT lors de la finalisation
              // pour éviter les duplications et garantir un historique cohérent
              // Les modifications des jours de production sont juste sauvegardées dans la session
              
              if (context.mounted) {
                ref.invalidate(stockStateProvider);
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Show machine breakdown dialog.
  static Future<void> showMachineBreakdown({
    required BuildContext context,
    required WidgetRef ref,
    required ProductionSession? session,
    required DateTime selectedDate,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
    required BobineUsage bobine,
    required int bobineIndex,
    required Function() onBobineRemoved,
  }) async {
    // Créer un objet Machine à partir des infos de la bobine
    final machine = Machine(
      id: bobine.machineId,
      nom: bobine.machineName,
      reference: bobine.machineId,
    );
    
    // Créer une session temporaire pour le dialog
    final tempSession = ProductionSession(
      id: session?.id ?? 'temp',
      date: selectedDate,
      period: 1,
      heureDebut: heureDebut,
      consommationCourant: 0,
      machinesUtilisees: machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees,
      quantiteProduite: 0,
      quantiteProduiteUnite: 'pack',
      events: session?.events ?? [],
    );

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => MachineBreakdownDialog(
        machine: machine,
        session: tempSession,
        bobine: bobine,
        onPanneSignaled: (event) {
          onBobineRemoved();
          // Invalider les providers pour rafraîchir les données
          ref.invalidate(productionSessionsStateProvider);
          if (session != null) {
            ref.invalidate(productionSessionDetailProvider((session.id)));
          }
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/bobine_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../widgets/machine_selector_field.dart';
import '../../widgets/bobine_usage_form_field.dart' show bobineStocksDisponiblesProvider;
import 'package:elyf_groupe_app/shared.dart';

/// Helper class for production session form actions.
/// Extracted from ProductionSessionFormSteps to reduce file size.
class ProductionSessionFormActions {
  /// Load unfinished bobines for selected machines.
  static Future<void> chargerBobinesNonFinies({
    required WidgetRef ref,
    required List<String> machinesSelectionnees,
    required Function(List<BobineUsage>) onBobinesChanged,
    required Function(Map<String, BobineUsage>) onMachinesAvecBobineChanged,
  }) async {
    if (machinesSelectionnees.isEmpty) {
      onBobinesChanged([]);
      onMachinesAvecBobineChanged({});
      return;
    }

    try {
      // Récupérer toutes les sessions précédentes pour vérifier l'état des machines
      final sessions = await ref.read(productionSessionsStateProvider.future);
      
      // Récupérer les machines et les stocks pour les noms et types disponibles
      final machines = await ref.read(machinesProvider.future);
      final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
      
      // Utiliser ProductionService pour charger les bobines non finies
      final productionService = ref.read(productionServiceProvider);
      final result = await productionService.chargerBobinesNonFinies(
        machinesSelectionnees: machinesSelectionnees,
        sessionsPrecedentes: sessions.toList(),
        machines: machines,
        bobineStocksDisponibles: bobineStocks,
      );

      // Mettre à jour la liste des bobines utilisées
      onBobinesChanged(result.bobinesUtilisees);
      onMachinesAvecBobineChanged(result.machinesAvecBobineNonFinie);
      
      debugPrint('Bobines assignées: ${result.bobinesUtilisees.length} pour ${machinesSelectionnees.length} machines');
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'état des machines: $e');
    }
  }

  /// Build a ProductionSession from form data.
  static ProductionSession buildSession({
    required String? sessionId,
    required DateTime selectedDate,
    required DateTime heureDebut,
    required DateTime? heureFin,
    required int? indexCompteurInitialKwh,
    required int? indexCompteurFinalKwh,
    required double consommationCourant,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
    required int quantiteProduite,
    required int? emballagesUtilises,
    required String? notes,
    required ProductionSessionStatus status,
    required List<ProductionDay> productionDays,
    required int period,
  }) {
    return ProductionSession(
      id: sessionId ?? '',
      date: selectedDate,
      period: period,
      heureDebut: heureDebut,
      heureFin: heureFin,
      indexCompteurInitialKwh: indexCompteurInitialKwh,
      indexCompteurFinalKwh: indexCompteurFinalKwh,
      consommationCourant: consommationCourant,
      machinesUtilisees: machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees,
      quantiteProduite: quantiteProduite,
      quantiteProduiteUnite: 'pack',
      emballagesUtilises: emballagesUtilises,
      notes: notes,
      status: status,
      productionDays: productionDays,
    );
  }

  /// Find existing unfinished session ID.
  static Future<String?> findExistingUnfinishedSessionId({
    required WidgetRef ref,
    required String? currentSessionId,
  }) async {
    if (currentSessionId != null && currentSessionId.isNotEmpty) {
      return currentSessionId;
    }

    final sessions = await ref.read(productionSessionsStateProvider.future);
    final sessionsNonTerminees = sessions.where(
      (s) => s.effectiveStatus != ProductionSessionStatus.completed,
    ).toList();
    
    if (sessionsNonTerminees.isNotEmpty) {
      return sessionsNonTerminees.first.id;
    }
    
    return null;
  }

  /// Validate current step.
  static bool validateStep({
    required FormState? formState,
    required ProductionSession? session,
    required int currentStep,
    required List<String> machinesSelectionnees,
    required List<BobineUsage> bobinesUtilisees,
    required int? indexCompteurInitialKwh,
    required String quantiteText,
    required int? indexCompteurFinalKwh,
    required String consommationText,
  }) {
    if (!(formState?.validate() ?? false)) {
      return false;
    }
    
    final isEditing = session != null;
    
    switch (currentStep) {
      case 0:
        // Démarrage : date, machines, index initial kWh
        if (isEditing) {
          return machinesSelectionnees.isNotEmpty &&
              bobinesUtilisees.length == machinesSelectionnees.length &&
              indexCompteurInitialKwh != null;
        } else {
          return machinesSelectionnees.isNotEmpty &&
              indexCompteurInitialKwh != null;
        }
      case 1:
        // Production : quantité produite (seulement en mode édition)
        return isEditing && quantiteText.isNotEmpty;
      case 2:
        // Finalisation : index final, consommation (seulement en mode édition)
        return isEditing && indexCompteurFinalKwh != null && consommationText.isNotEmpty;
      default:
        return true;
    }
  }

  /// Calculate session status.
  static ProductionSessionStatus calculateStatus({
    required WidgetRef ref,
    required int quantiteProduite,
    required DateTime? heureFin,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
  }) {
    final productionService = ref.read(productionServiceProvider);
    return productionService.calculateStatus(
      quantiteProduite: quantiteProduite,
      heureFin: heureFin,
      heureDebut: heureDebut,
      machinesUtilisees: machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees,
    );
  }
}


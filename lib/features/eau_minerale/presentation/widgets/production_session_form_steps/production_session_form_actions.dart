import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/machine_material_usage.dart';
import '../../widgets/machine_selector_field.dart';
import '../../widgets/machine_material_usage_form_field.dart'
    show machineMaterialsDisponiblesProvider;

/// Helper class for production session form actions.
class ProductionSessionFormActions {
  /// Load unfinished machine materials for selected machines.
  static Future<void> chargerMatieresNonFinies({
    required WidgetRef ref,
    required List<String> machinesSelectionnees,
    required Function(List<MachineMaterialUsage>) onMaterialsChanged,
    required Function(Map<String, MachineMaterialUsage>) onMachinesAvecMatiereChanged,
    List<MachineMaterialUsage>? materialsExistants,
  }) async {
    if (machinesSelectionnees.isEmpty) {
      onMaterialsChanged([]);
      onMachinesAvecMatiereChanged({});
      return;
    }

    try {
      final sessions = await ref.read(productionSessionsStateProvider.future);
      final machines = await ref.read(machinesProvider.future);
      final materialStocks = await ref.read(
        machineMaterialsDisponiblesProvider.future,
      );

      final productionService = ref.read(productionServiceProvider);
      // Note: ProductionService needs to be updated too if it has 'bobine' naming
      final result = await productionService.chargerMatieresNonFinies(
        machinesSelectionnees: machinesSelectionnees,
        sessionsPrecedentes: sessions.toList(),
        machines: machines,
        materialStocksDisponibles: materialStocks,
        materialsExistantsParam: materialsExistants,
      );

      onMaterialsChanged(result.machineMaterials);
      onMachinesAvecMatiereChanged(result.machinesAvecMatiereNonFinie);

      AppLogger.debug(
        'Matières assignées: ${result.machineMaterials.length} pour ${machinesSelectionnees.length} machines',
        name: 'eau_minerale.production',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la vérification de l\'état des machines: $e',
        name: 'eau_minerale.production',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Build a ProductionSession from form data.
  static ProductionSession buildSession({
    required String? sessionId,
    required String enterpriseId,
    required DateTime selectedDate,
    required DateTime heureDebut,
    required DateTime? heureFin,
    required int? indexCompteurInitialKwh,
    required int? indexCompteurFinalKwh,
    required double consommationCourant,
    required List<String> machinesUtilisees,
    required List<MachineMaterialUsage> machineMaterials,
    required int quantiteProduite,
    required int? emballagesUtilises,
    required String? notes,
    required ProductionSessionStatus status,
    required List<ProductionDay> productionDays,
    required int period,
    int? machineMaterialCost,
    int? coutEmballages,
    int? coutElectricite,
  }) {
    return ProductionSession(
      id: sessionId ?? '',
      enterpriseId: enterpriseId,
      date: selectedDate,
      period: period,
      heureDebut: heureDebut,
      heureFin: heureFin,
      indexCompteurInitialKwh: indexCompteurInitialKwh,
      indexCompteurFinalKwh: indexCompteurFinalKwh,
      consommationCourant: consommationCourant,
      machinesUtilisees: machinesUtilisees,
      machineMaterials: machineMaterials,
      quantiteProduite: quantiteProduite,
      quantiteProduiteUnite: 'pack',
      emballagesUtilises: emballagesUtilises,
      notes: notes,
      status: status,
      productionDays: productionDays,
      machineMaterialCost: machineMaterialCost,
      coutEmballages: coutEmballages,
      coutElectricite: coutElectricite,
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
    final sessionsNonTerminees = sessions
        .where((s) => s.effectiveStatus != ProductionSessionStatus.completed)
        .toList();

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
    required List<MachineMaterialUsage> machineMaterials,
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
        if (isEditing) {
          return machinesSelectionnees.isNotEmpty &&
              machineMaterials.length == machinesSelectionnees.length &&
              indexCompteurInitialKwh != null;
        } else {
          return machinesSelectionnees.isNotEmpty &&
              indexCompteurInitialKwh != null;
        }
      case 1:
        return isEditing && quantiteText.isNotEmpty;
      case 2:
        return isEditing &&
            indexCompteurFinalKwh != null &&
            consommationText.isNotEmpty;
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
    required List<MachineMaterialUsage> machineMaterials,
  }) {
    final productionService = ref.read(productionServiceProvider);
    return productionService.calculateStatus(
      quantiteProduite: quantiteProduite,
      heureFin: heureFin,
      heureDebut: heureDebut,
      machinesUtilisees: machinesUtilisees,
      machineMaterials: machineMaterials,
    );
  }
}

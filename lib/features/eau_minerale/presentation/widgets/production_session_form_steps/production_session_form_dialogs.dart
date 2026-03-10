import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../domain/entities/machine_material_usage.dart';
import '../../../domain/entities/machine.dart';
import '../../../domain/entities/production_day.dart';
import '../../../domain/entities/production_session.dart';
import '../../widgets/machine_material_installation_form.dart';
import '../../widgets/daily_personnel_form.dart';
import '../../widgets/machine_breakdown_dialog.dart';
import '../../widgets/machine_selector_field.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Helper class for production session form dialogs.
class ProductionSessionFormDialogs {
  /// Show machine material installation dialog.
  static Future<void> showMaterialInstallation({
    required BuildContext context,
    required WidgetRef ref,
    required List<String> machinesSelectionnees,
    required List<MachineMaterialUsage> machineMaterials,
    required Function(List<MachineMaterialUsage>) onMaterialsChanged,
  }) async {
    final machinesAvecMatiere = machineMaterials.map((b) => b.machineId).toSet();
    final machinesSansMatiere = machinesSelectionnees
        .where((mId) => !machinesAvecMatiere.contains(mId))
        .toList();

    if (machinesSansMatiere.isEmpty) {
      NotificationService.showInfo(
        context,
        'Toutes les machines ont une matière',
      );
      return;
    }

    final machines = await ref.read(machinesProvider.future);
    final machine = machines.firstWhere(
      (m) => m.id == machinesSansMatiere.first,
    );

    if (!context.mounted) return;
    final result = await showDialog<MachineMaterialUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: MachineMaterialInstallationForm(
          machine: machine,
        ),
      ),
    );

    if (result != null && context.mounted) {
      final existeDeja = machineMaterials.any(
        (b) =>
            b.materialType == result.materialType &&
            b.machineId == result.machineId,
      );

      if (!existeDeja) {
        final updatedMaterials = List<MachineMaterialUsage>.from(machineMaterials)
          ..add(result);
        onMaterialsChanged(updatedMaterials);
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
    required List<MachineMaterialUsage> machineMaterials,
    required List<ProductionDay> productionDays,
    required DateTime date,
    required Function(ProductionDay) onDayAdded,
    required Function(ProductionDay) onDayUpdated,
  }) async {
    final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';

    final tempSession = ProductionSession(
      id: session?.id ?? 'temp',
      enterpriseId: enterpriseId,
      date: selectedDate,
      period: 1,
      heureDebut: heureDebut,
      consommationCourant: 0,
      machinesUtilisees: machinesUtilisees,
      machineMaterials: machineMaterials,
      quantiteProduite: 0,
      quantiteProduiteUnite: 'pack',
      productionDays: productionDays,
    );

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
    required List<MachineMaterialUsage> machineMaterials,
    required MachineMaterialUsage material,
    required int materialIndex,
    required Function() onMaterialRemoved,
  }) async {
    final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';
    
    final machine = Machine(
      id: material.machineId,
      name: material.machineName,
      enterpriseId: enterpriseId,
      reference: material.machineId,
    );

    final tempSession = ProductionSession(
      id: session?.id ?? 'temp',
      enterpriseId: enterpriseId,
      date: selectedDate,
      period: 1,
      heureDebut: heureDebut,
      consommationCourant: 0,
      machinesUtilisees: machinesUtilisees,
      machineMaterials: machineMaterials,
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
        material: material,
        onPanneSignaled: (event) {
          onMaterialRemoved();
          ref.invalidate(productionSessionsStateProvider);
          if (session != null) {
            ref.invalidate(productionSessionDetailProvider((session.id)));
          }
        },
      ),
    );
  }
}

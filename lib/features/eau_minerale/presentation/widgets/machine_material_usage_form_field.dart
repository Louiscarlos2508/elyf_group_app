import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine_material_usage.dart';
import 'machine_material_usage_item_form.dart';
import 'machine_selector_field.dart' show machinesProvider;
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Champ pour gérer les matières utilisées sur les machines dans une session.
class MachineMaterialUsageFormField extends ConsumerWidget {
  const MachineMaterialUsageFormField({
    super.key,
    required this.materials,
    required this.machinesDisponibles,
    required this.onMaterialsChanged,
  });

  static const maxMaterials = 20;

  final List<MachineMaterialUsage> materials;
  final List<String> machinesDisponibles;
  final ValueChanged<List<MachineMaterialUsage>> onMaterialsChanged;

  Future<void> _ajouterMatiere(BuildContext context, WidgetRef ref) async {
    if (materials.length >= maxMaterials) {
      if (!context.mounted) return;
      NotificationService.showError(
        context,
        'Maximum $maxMaterials matières autorisées',
      );
      return;
    }

    final materialStocks = await ref.read(machineMaterialsDisponiblesProvider.future);
    final machines = await ref.read(machinesProvider.future);

    final machinesAvecMatiere = materials.map((u) => u.machineId).toSet();
    final machinesDisponiblesFiltrees = machines
        .where((m) => machinesDisponibles.contains(m.id))
        .where((m) => !machinesAvecMatiere.contains(m.id))
        .toList();

    if (machinesDisponiblesFiltrees.isEmpty) {
      if (!context.mounted) return;
      NotificationService.showInfo(
        context,
        'Toutes les machines ont déjà une matière',
      );
      return;
    }

    if (materialStocks.isEmpty) {
      if (!context.mounted) return;
      NotificationService.showInfo(
        context,
        'Aucune matière disponible en stock',
      );
      return;
    }

    if (!context.mounted) return;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final maxDialogWidth = (screenWidth * 0.9).clamp(400.0, 600.0);

    final result = await showDialog<MachineMaterialUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: MachineMaterialUsageItemForm(
              materialStocksDisponibles: materialStocks,
              machinesDisponibles: machinesDisponiblesFiltrees,
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      final nouvellesMatieres = List<MachineMaterialUsage>.from(materials);
      nouvellesMatieres.add(result);
      onMaterialsChanged(nouvellesMatieres);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canAddMore = materials.length < maxMaterials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Matières installées (Machines)', style: theme.textTheme.titleSmall),
                  if (materials.isNotEmpty)
                    Text(
                      '${materials.length} matière(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: canAddMore ? () => _ajouterMatiere(context, ref) : null,
              tooltip: canAddMore
                  ? 'Ajouter matière'
                  : 'Maximum $maxMaterials matières autorisées',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (materials.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Aucune matière ajoutée',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                return Card(
                  margin: EdgeInsets.only(
                    bottom: index < materials.length - 1 ? 8 : 0,
                  ),
                  child: ListTile(
                    title: Text(material.materialType),
                    subtitle: Text('Machine: ${material.machineName}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        final nouvellesMatieres = List<MachineMaterialUsage>.from(
                          materials,
                        );
                        nouvellesMatieres.removeAt(index);
                        onMaterialsChanged(nouvellesMatieres);
                      },
                      tooltip: 'Supprimer',
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Provider pour récupérer les stocks de matières machine disponibles.
final machineMaterialsDisponiblesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final state = await ref.read(stockStateProvider.future);
  return state.items.where((i) => i.type == StockType.rawMaterial).toList(); 
});

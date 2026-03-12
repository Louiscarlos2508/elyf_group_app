import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine_material_usage.dart';

/// Formulaire pour ajouter une matière utilisée sur une machine.
/// (Anciennement BobineUsageItemForm).
class MachineMaterialUsageItemForm extends ConsumerStatefulWidget {
  const MachineMaterialUsageItemForm({
    super.key,
    required this.materialStocksDisponibles,
    required this.machinesDisponibles,
  });

  final List<dynamic> materialStocksDisponibles;
  final List<Machine> machinesDisponibles;

  @override
  ConsumerState<MachineMaterialUsageItemForm> createState() =>
      _MachineMaterialUsageItemFormState();
}

class _MachineMaterialUsageItemFormState extends ConsumerState<MachineMaterialUsageItemForm> {
  final formKey = GlobalKey<FormState>();
  Machine? _machineSelectionnee;

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    if (widget.materialStocksDisponibles.isEmpty) {
      NotificationService.showWarning(
        context,
        'Aucune matière disponible en stock',
      );
      return;
    }
    if (_machineSelectionnee == null) {
      NotificationService.showWarning(context, 'Sélectionnez une machine');
      return;
    }

    // Prendre automatiquement le premier type de matière disponible
    // Dans une version future, on pourrait laisser choisir si plusieurs types
    final stock = widget.materialStocksDisponibles.first;

    final now = DateTime.now();
    final usage = MachineMaterialUsage(
      id: const Uuid().v4(),
      materialType: stock.type,
      machineId: _machineSelectionnee!.id,
      machineName: _machineSelectionnee!.name,
      dateInstallation: now,
      heureInstallation: now,
      dateUtilisation: now,
      productId: stock.productId, // Supposant que stock a productId
      productName: stock.name,
      isReused: false,
    );

    Navigator.of(context).pop(usage);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.materialStocksDisponibles.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune matière disponible en stock',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Une matière sera automatiquement assignée',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${widget.materialStocksDisponibles.length} type(s) disponible(s)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Machine>(
            initialValue: _machineSelectionnee,
            decoration: const InputDecoration(
              labelText: 'Machine',
              prefixIcon: Icon(Icons.precision_manufacturing),
            ),
            items: widget.machinesDisponibles.map((machine) {
              return DropdownMenuItem(value: machine, child: Text(machine.name));
            }).toList(),
            onChanged: (machine) {
              setState(() => _machineSelectionnee = machine);
            },
            validator: (value) {
              final validationService = ref.read(
                productionValidationServiceProvider,
              );
              return validationService.validateMachineSelection(value);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.materialStocksDisponibles.isEmpty ? null : _submit,
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

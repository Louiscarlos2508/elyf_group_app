import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';

/// Formulaire pour ajouter une bobine utilisée.
class BobineUsageItemForm extends ConsumerStatefulWidget {
  const BobineUsageItemForm({
    super.key,
    required this.bobineStocksDisponibles,
    required this.machinesDisponibles,
  });

  final List<BobineStock> bobineStocksDisponibles;
  final List<Machine> machinesDisponibles;

  @override
  ConsumerState<BobineUsageItemForm> createState() =>
      _BobineUsageItemFormState();
}

class _BobineUsageItemFormState extends ConsumerState<BobineUsageItemForm> {
  final formKey = GlobalKey<FormState>();
  Machine? _machineSelectionnee;

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    if (widget.bobineStocksDisponibles.isEmpty) {
      NotificationService.showWarning(
        context,
        'Aucune bobine disponible en stock',
      );
      return;
    }
    if (_machineSelectionnee == null) {
      NotificationService.showWarning(context, 'Sélectionnez une machine');
      return;
    }

    // Prendre automatiquement le premier type de bobine disponible
    final bobineStock = widget.bobineStocksDisponibles.first;

    final now = DateTime.now();
    final usage = BobineUsage(
      bobineType: bobineStock.type,
      machineId: _machineSelectionnee!.id,
      machineName: _machineSelectionnee!.nom,
      dateInstallation: now,
      heureInstallation: now,
      dateUtilisation: now,
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
          if (widget.bobineStocksDisponibles.isEmpty)
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
                      'Aucune bobine disponible en stock',
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
                          'Une bobine sera automatiquement assignée',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${widget.bobineStocksDisponibles.fold<int>(0, (sum, stock) => sum + stock.quantity)} bobine${widget.bobineStocksDisponibles.fold<int>(0, (sum, stock) => sum + stock.quantity) > 1 ? 's' : ''} disponible${widget.bobineStocksDisponibles.fold<int>(0, (sum, stock) => sum + stock.quantity) > 1 ? 's' : ''}',
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
              return DropdownMenuItem(value: machine, child: Text(machine.nom));
            }).toList(),
            onChanged: (machine) {
              setState(() => _machineSelectionnee = machine);
            },
            validator: (value) {
              // Utiliser le service de validation pour extraire la logique métier
              final validationService = ref.read(
                productionValidationServiceProvider,
              );
              return validationService.validateMachineSelection(value);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.bobineStocksDisponibles.isEmpty ? null : _submit,
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bobine.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';

/// Formulaire pour ajouter une bobine utilisée.
class BobineUsageItemForm extends ConsumerStatefulWidget {
  const BobineUsageItemForm({
    super.key,
    required this.bobinesDisponibles,
    required this.machinesDisponibles,
  });

  final List<Bobine> bobinesDisponibles;
  final List<Machine> machinesDisponibles;

  @override
  ConsumerState<BobineUsageItemForm> createState() =>
      _BobineUsageItemFormState();
}

class _BobineUsageItemFormState
    extends ConsumerState<BobineUsageItemForm> {
  final formKey = GlobalKey<FormState>();
  Bobine? _bobineSelectionnee;
  Machine? _machineSelectionnee;
  final _poidsInitialController = TextEditingController();
  final _poidsFinalController = TextEditingController();

  @override
  void dispose() {
    _poidsInitialController.dispose();
    _poidsFinalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    if (_bobineSelectionnee == null || _machineSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une bobine et une machine')),
      );
      return;
    }

    final usage = BobineUsage(
      bobineId: _bobineSelectionnee!.id,
      bobineReference: _bobineSelectionnee!.reference,
      poidsInitial: double.parse(_poidsInitialController.text),
      poidsFinal: double.parse(_poidsFinalController.text),
      machineId: _machineSelectionnee!.id,
      machineName: _machineSelectionnee!.nom,
      dateUtilisation: DateTime.now(),
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
          DropdownButtonFormField<Bobine>(
            value: _bobineSelectionnee,
            decoration: const InputDecoration(
              labelText: 'Bobine',
              prefixIcon: Icon(Icons.inventory),
            ),
            items: widget.bobinesDisponibles.map((bobine) {
              return DropdownMenuItem(
                value: bobine,
                child: Text(
                  '${bobine.reference} (${bobine.poidsActuel.toStringAsFixed(2)}kg)',
                ),
              );
            }).toList(),
            onChanged: (bobine) {
              setState(() {
                _bobineSelectionnee = bobine;
                if (bobine != null) {
                  _poidsInitialController.text =
                      bobine.poidsActuel.toStringAsFixed(2);
                }
              });
            },
            validator: (value) =>
                value == null ? 'Sélectionnez une bobine' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Machine>(
            value: _machineSelectionnee,
            decoration: const InputDecoration(
              labelText: 'Machine',
              prefixIcon: Icon(Icons.precision_manufacturing),
            ),
            items: widget.machinesDisponibles.map((machine) {
              return DropdownMenuItem(
                value: machine,
                child: Text(machine.nom),
              );
            }).toList(),
            onChanged: (machine) {
              setState(() => _machineSelectionnee = machine);
            },
            validator: (value) =>
                value == null ? 'Sélectionnez une machine' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _poidsInitialController,
            decoration: const InputDecoration(
              labelText: 'Poids initial (kg)',
              prefixIcon: Icon(Icons.scale),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requis';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Nombre invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _poidsFinalController,
            decoration: const InputDecoration(
              labelText: 'Poids final (kg)',
              prefixIcon: Icon(Icons.scale),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requis';
              }
              final poidsFinal = double.tryParse(value);
              if (poidsFinal == null || poidsFinal < 0) {
                return 'Nombre invalide';
              }
              final poidsInitial =
                  double.tryParse(_poidsInitialController.text);
              if (poidsInitial != null && poidsFinal > poidsInitial) {
                return 'Doit être <= poids initial';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}


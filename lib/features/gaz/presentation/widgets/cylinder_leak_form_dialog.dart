import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/cylinder_leak_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';

/// Formulaire de déclaration d'une bouteille avec fuite.
class CylinderLeakFormDialog extends ConsumerStatefulWidget {
  const CylinderLeakFormDialog({
    super.key,
    this.cylinderId,
    this.weight,
  });

  final String? cylinderId;
  final int? weight;

  @override
  ConsumerState<CylinderLeakFormDialog> createState() =>
      _CylinderLeakFormDialogState();
}

class _CylinderLeakFormDialogState
    extends ConsumerState<CylinderLeakFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cylinderIdController = TextEditingController();
  int? _selectedWeight;
  final _notesController = TextEditingController();
  String? _enterpriseId;

  final List<int> _availableWeights = [3, 6, 10, 12];

  @override
  void initState() {
    super.initState();
    if (widget.cylinderId != null) {
      _cylinderIdController.text = widget.cylinderId!;
    }
    if (widget.weight != null) {
      _selectedWeight = widget.weight;
    }
  }

  @override
  void dispose() {
    _cylinderIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedWeight == null ||
        _enterpriseId == null) {
      return;
    }

    try {
      final controller = ref.read(cylinderLeakControllerProvider);
      await controller.reportLeak(
        _cylinderIdController.text,
        _selectedWeight!,
        _enterpriseId!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Signaler une Fuite',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cylinderIdController,
                decoration: const InputDecoration(
                  labelText: 'ID Bouteille',
                  border: OutlineInputBorder(),
                  helperText: 'Identifiant de la bouteille',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ID requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedWeight,
                decoration: const InputDecoration(
                  labelText: 'Poids (kg)',
                  border: OutlineInputBorder(),
                ),
                items: _availableWeights.map((weight) {
                  return DropdownMenuItem(
                    value: weight,
                    child: Text('$weight kg'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedWeight = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Poids requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                  helperText: 'Détails sur la fuite détectée',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Signaler'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
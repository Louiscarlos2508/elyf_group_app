import '../../../../../shared/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';

/// Formulaire de déclaration d'une bouteille avec fuite.
class CylinderLeakFormDialog extends ConsumerStatefulWidget {
  const CylinderLeakFormDialog({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
    this.cylinderId,
    this.weight,
    this.tourId,
  });

  final String enterpriseId;
  final String moduleId;
  final String? cylinderId;
  final int? weight;
  final String?
  tourId; // ID du tour d'approvisionnement (si signalé depuis un tour)

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
    if (!_formKey.currentState!.validate() || _selectedWeight == null) {
      return;
    }

    try {
      final controller = ref.read(cylinderLeakControllerProvider);
      await controller.reportLeak(
        _cylinderIdController.text,
        _selectedWeight!,
        widget.enterpriseId,
        tourId: widget.tourId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  /// Récupère les poids disponibles depuis les bouteilles créées.
  List<int> _getAvailableWeights(WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);
    return cylindersAsync.when(
      data: (cylinders) {
        // Filtrer par entreprise et module, puis extraire les poids uniques
        final filteredCylinders = cylinders
            .where(
              (c) =>
                  c.enterpriseId == widget.enterpriseId &&
                  c.moduleId == widget.moduleId,
            )
            .toList();
        final weights = filteredCylinders.map((c) => c.weight).toSet().toList();
        weights.sort();
        return weights;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableWeights = _getAvailableWeights(ref);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signaler une Fuite',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextFormField(
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: availableWeights.isEmpty
                    ? TextFormField(
                        initialValue: _selectedWeight?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Poids (kg) *',
                          border: OutlineInputBorder(),
                          helperText:
                              'Aucune bouteille créée. Entrez le poids manuellement.',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _selectedWeight = int.tryParse(value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Poids requis';
                          }
                          final weight = int.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Le poids doit être un nombre positif';
                          }
                          return null;
                        },
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: _selectedWeight,
                        decoration: const InputDecoration(
                          labelText: 'Poids (kg) *',
                          border: OutlineInputBorder(),
                        ),
                        items: availableWeights.map((weight) {
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    border: OutlineInputBorder(),
                    helperText: 'Détails sur la fuite détectée',
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Signaler'),
                    ),
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

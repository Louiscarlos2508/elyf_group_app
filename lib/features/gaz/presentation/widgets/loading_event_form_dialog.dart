import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/loading_event_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/loading_event.dart';

/// Formulaire de création d'un événement de chargement.
class LoadingEventFormDialog extends ConsumerStatefulWidget {
  const LoadingEventFormDialog({super.key});

  @override
  ConsumerState<LoadingEventFormDialog> createState() =>
      _LoadingEventFormDialogState();
}

class _LoadingEventFormDialogState
    extends ConsumerState<LoadingEventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, int> _emptyCylinders = {};
  final _notesController = TextEditingController();
  String? _enterpriseId;

  final List<int> _availableWeights = [3, 6, 10, 12];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _enterpriseId == null) {
      return;
    }

    try {
      final controller = ref.read(loadingEventControllerProvider);
      await controller.createLoadingEvent(
        _enterpriseId!,
        _emptyCylinders,
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
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nouvel Événement de Chargement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ..._availableWeights.map((weight) => _QuantityField(
                    weight: weight,
                    onChanged: (qty) {
                      if (qty > 0) {
                        _emptyCylinders[weight] = qty;
                      } else {
                        _emptyCylinders.remove(weight);
                      }
                    },
                  )),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                      onPressed: _emptyCylinders.isEmpty
                          ? null
                          : () async {
                              await _submit();
                            },
                      child: const Text('Créer'),
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

class _QuantityField extends StatefulWidget {
  const _QuantityField({
    required this.weight,
    required this.onChanged,
  });

  final int weight;
  final ValueChanged<int> onChanged;

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  final _controller = TextEditingController(text: '0');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text('Bouteilles ${widget.weight}kg vides:'),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                final qty = int.tryParse(value) ?? 0;
                widget.onChanged(qty);
              },
            ),
          ),
        ],
      ),
    );
  }
}
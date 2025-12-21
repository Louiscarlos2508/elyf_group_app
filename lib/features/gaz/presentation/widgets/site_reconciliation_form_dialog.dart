import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/site_reconciliation_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/site_reconciliation.dart';
import 'payment_proof_input_widget.dart';

/// Formulaire de création d'une réconciliation de site.
class SiteReconciliationFormDialog extends ConsumerStatefulWidget {
  const SiteReconciliationFormDialog({
    super.key,
    required this.siteId,
  });

  final String siteId;

  @override
  ConsumerState<SiteReconciliationFormDialog> createState() =>
      _SiteReconciliationFormDialogState();
}

class _SiteReconciliationFormDialogState
    extends ConsumerState<SiteReconciliationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _paymentProofUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<int, int> _expectedCylinders = {};
  final Map<int, int> _actualCylinders = {};
  String? _enterpriseId;

  final List<int> _availableWeights = [3, 6, 10, 12];

  @override
  void dispose() {
    _cashController.dispose();
    _paymentProofUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _enterpriseId == null) {
      return;
    }

    if (_expectedCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir les bouteilles attendues')),
      );
      return;
    }

    if (_actualCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir les bouteilles réelles')),
      );
      return;
    }

    try {
      final controller = ref.read(siteReconciliationControllerProvider);
      final cash = double.tryParse(_cashController.text) ?? 0.0;

      await controller.createReconciliation(
        widget.siteId,
        _enterpriseId!,
        cash,
        _expectedCylinders,
        _actualCylinders,
        paymentProofUrl:
            _paymentProofUrlController.text.isEmpty
                ? null
                : _paymentProofUrlController.text,
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
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nouvelle Réconciliation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _cashController,
                  decoration: const InputDecoration(
                    labelText: 'Montant Cash Transféré (FCFA)',
                    border: OutlineInputBorder(),
                    prefixText: '₣ ',
                    helperText: 'Ex: Orange Money',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Montant requis';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PaymentProofInputWidget(
                  initialUrl: _paymentProofUrlController.text.isEmpty
                      ? null
                      : _paymentProofUrlController.text,
                  onUrlChanged: (url) {
                    _paymentProofUrlController.text = url;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Bouteilles Attendues',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._availableWeights.map((weight) => _QuantityField(
                      weight: weight,
                      label: 'Attendu',
                      onChanged: (qty) {
                        if (qty > 0) {
                          _expectedCylinders[weight] = qty;
                        } else {
                          _expectedCylinders.remove(weight);
                        }
                      },
                    )),
                const SizedBox(height: 24),
                Text(
                  'Bouteilles Réellement Vendues',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._availableWeights.map((weight) => _QuantityField(
                      weight: weight,
                      label: 'Réel',
                      onChanged: (qty) {
                        if (qty > 0) {
                          _actualCylinders[weight] = qty;
                        } else {
                          _actualCylinders.remove(weight);
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
                  maxLines: 2,
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
                        child: const Text('Créer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityField extends StatefulWidget {
  const _QuantityField({
    required this.weight,
    required this.label,
    required this.onChanged,
  });

  final int weight;
  final String label;
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text('${widget.weight}kg (${widget.label}):'),
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
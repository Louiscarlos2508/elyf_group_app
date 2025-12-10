import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/providers/treasury_providers.dart';
import '../../../core/domain/entities/treasury_movement.dart';

/// Dialog pour effectuer un transfert entre Cash et Orange Money.
class TreasuryTransferDialog extends ConsumerStatefulWidget {
  const TreasuryTransferDialog({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  final String moduleId;
  final String moduleName;

  @override
  ConsumerState<TreasuryTransferDialog> createState() =>
      _TreasuryTransferDialogState();
}

class _TreasuryTransferDialogState
    extends ConsumerState<TreasuryTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  PaymentMethod _fromMethod = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  PaymentMethod get _toMethod {
    return _fromMethod == PaymentMethod.cash
        ? PaymentMethod.orangeMoney
        : PaymentMethod.cash;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final controller = ref.read(treasuryControllerProvider);
      await controller.transfer(
        moduleId: widget.moduleId,
        amount: amount,
        fromMethod: _fromMethod,
        toMethod: _toMethod,
        description: _descriptionController.text.isEmpty
            ? 'Transfert ${_getMethodLabel(_fromMethod)} → ${_getMethodLabel(_toMethod)}'
            : _descriptionController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(treasuryProvider(widget.moduleId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfert effectué avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transfert - ${widget.moduleName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'De',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('Cash'),
                    icon: Icon(Icons.money),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.orangeMoney,
                    label: Text('Orange Money'),
                    icon: Icon(Icons.account_balance_wallet),
                  ),
                ],
                selected: {_fromMethod},
                onSelectionChanged: (Set<PaymentMethod> selection) {
                  setState(() => _fromMethod = selection.first);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Vers',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _toMethod == PaymentMethod.cash
                          ? Icons.money
                          : Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getMethodLabel(_toMethod),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  helperText: 'Optionnel',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Effectuer le transfert'),
        ),
      ],
    );
  }
}


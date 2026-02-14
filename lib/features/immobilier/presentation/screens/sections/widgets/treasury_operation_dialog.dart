import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/domain/entities/payment_method.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/treasury_operation.dart';
import '../../../../../../core/tenant/tenant_provider.dart';

class TreasuryOperationDialog extends StatefulWidget {
  final TreasuryOperationType type;

  const TreasuryOperationDialog({super.key, required this.type});

  @override
  State<TreasuryOperationDialog> createState() => _TreasuryOperationDialogState();
}

class _TreasuryOperationDialogState extends State<TreasuryOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _recipientController = TextEditingController();
  String? _reason;
  PaymentMethod? _fromAccount;
  PaymentMethod? _toAccount;

  @override
  void initState() {
    super.initState();
    // Default values based on type
    if (widget.type == TreasuryOperationType.supply) {
      _toAccount = PaymentMethod.cash;
    } else if (widget.type == TreasuryOperationType.removal) {
      _fromAccount = PaymentMethod.cash;
    } else if (widget.type == TreasuryOperationType.transfer) {
      _fromAccount = PaymentMethod.cash;
      _toAccount = PaymentMethod.mobileMoney;
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    switch (widget.type) {
      case TreasuryOperationType.supply: title = 'Nouvel Apport'; break;
      case TreasuryOperationType.removal: title = 'Nouveau Retrait'; break;
      case TreasuryOperationType.transfer: title = 'Nouveau Transfert'; break;
      case TreasuryOperationType.adjustment: title = 'Nouvel Ajustement'; break;
    }

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant (CFA)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              if (widget.type == TreasuryOperationType.transfer || widget.type == TreasuryOperationType.removal)
                DropdownButtonFormField<PaymentMethod>(
                  key: ValueKey(_fromAccount),
                  initialValue: _fromAccount,
                  decoration: const InputDecoration(labelText: 'Depuis le compte'),
                  items: [
                    DropdownMenuItem(value: PaymentMethod.cash, child: const Text('Caisse (Espèces)')),
                    DropdownMenuItem(value: PaymentMethod.mobileMoney, child: const Text('Mobile Money')),
                  ],
                  onChanged: (v) => setState(() => _fromAccount = v),
                ),
              if (widget.type == TreasuryOperationType.removal)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_reason),
                    initialValue: _reason,
                    decoration: const InputDecoration(labelText: 'Motif du retrait'),
                    items: const [
                      DropdownMenuItem(value: 'Retrait Propriétaire', child: Text('Retrait Propriétaire')),
                      DropdownMenuItem(value: 'Versement Banque', child: Text('Versement Banque')),
                      DropdownMenuItem(value: 'Petite Dépense', child: Text('Petite Dépense vs Caisse')),
                      DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                    ],
                    onChanged: (v) => setState(() => _reason = v),
                  ),
                ),
              if (widget.type == TreasuryOperationType.removal)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _recipientController,
                    decoration: const InputDecoration(labelText: 'Bénéficiaire'),
                    validator: (value) => (widget.type == TreasuryOperationType.removal && (value == null || value.isEmpty)) 
                        ? 'Le nom du bénéficiaire est requis' : null,
                  ),
                ),
              if (widget.type == TreasuryOperationType.transfer || widget.type == TreasuryOperationType.supply || widget.type == TreasuryOperationType.adjustment)
                DropdownButtonFormField<PaymentMethod>(
                  key: ValueKey(_toAccount),
                  initialValue: _toAccount,
                  decoration: const InputDecoration(labelText: 'Vers le compte'),
                  items: [
                    DropdownMenuItem(value: PaymentMethod.cash, child: const Text('Caisse (Espèces)')),
                    DropdownMenuItem(value: PaymentMethod.mobileMoney, child: const Text('Mobile Money')),
                  ],
                  onChanged: (v) => setState(() => _toAccount = v),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes / Justification'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        Consumer(builder: (context, ref, _) {
          return ElevatedButton(
            onPressed: () => _submit(ref),
            child: const Text('Enregistrer'),
          );
        }),
      ],
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
    
    final operation = TreasuryOperation(
      id: '', // Generated by repo
      enterpriseId: enterpriseId,
      userId: '', // Set by controller
      amount: int.parse(_amountController.text),
      type: widget.type,
      fromAccount: _fromAccount,
      toAccount: _toAccount,
      date: DateTime.now(),
      reason: _reason,
      recipient: _recipientController.text,
      notes: _notesController.text,
    );

    try {
      await ref.read(treasuryControllerProvider).recordOperation(operation);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart' show LocalIdGenerator;
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

class GazTreasuryOperationDialog extends ConsumerStatefulWidget {
  final TreasuryOperationType type;

  const GazTreasuryOperationDialog({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<GazTreasuryOperationDialog> createState() => _GazTreasuryOperationDialogState();
}

class _GazTreasuryOperationDialogState extends ConsumerState<GazTreasuryOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  
  PaymentMethod? _fromAccount;
  PaymentMethod? _toAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default accounts based on type
    if (widget.type == TreasuryOperationType.supply) {
      _toAccount = PaymentMethod.cash;
    } else if (widget.type == TreasuryOperationType.removal) {
      _fromAccount = PaymentMethod.cash;
    } else if (widget.type == TreasuryOperationType.transfer) {
      _fromAccount = PaymentMethod.cash;
      _toAccount = PaymentMethod.mobileMoney;
    } else if (widget.type == TreasuryOperationType.adjustment) {
      _toAccount = PaymentMethod.cash;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _recipientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value;
      if (activeEnterpriseId == null) throw Exception('Entreprise active non trouvée');

      final operation = TreasuryOperation(
        id: LocalIdGenerator.generate(),
        enterpriseId: activeEnterpriseId,
        userId: '', // TODO: Get from auth if available
        amount: int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        type: widget.type,
        fromAccount: _fromAccount,
        toAccount: _toAccount,
        date: DateTime.now(),
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
        recipient: _recipientController.text.isNotEmpty ? _recipientController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
      );

      await ref.read(gazTreasuryRepositoryProvider).saveOperation(operation);
      
      // Invalidate providers
      ref.invalidate(gazTreasuryBalanceProvider(activeEnterpriseId));
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opération enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getOperationColor();
    final title = _getOperationTitle();

    return AlertDialog(
      title: Row(
        children: [
          Icon(_getOperationIcon(), color: color),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Selection
              if (widget.type == TreasuryOperationType.transfer) ...[
                _buildAccountDropdown(
                  label: 'Source',
                  value: _fromAccount,
                  onChanged: (v) => setState(() => _fromAccount = v),
                ),
                const SizedBox(height: 16),
                _buildAccountDropdown(
                  label: 'Destination',
                  value: _toAccount,
                  onChanged: (v) => setState(() => _toAccount = v),
                ),
              ] else if (widget.type == TreasuryOperationType.removal) ...[
                _buildAccountDropdown(
                  label: 'Compte source',
                  value: _fromAccount,
                  onChanged: (v) => setState(() => _fromAccount = v),
                ),
              ] else ...[
                _buildAccountDropdown(
                  label: 'Compte destination',
                  value: _toAccount,
                  onChanged: (v) => setState(() => _toAccount = v),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (CFA)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  final amount = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (amount == null) return 'Nombre invalide';
                  if (amount <= 0) return 'Le montant doit être > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif / Raison',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Bénéficiaire / Provenance',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optionnel)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
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
          child: const Text('ANNULER'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('ENREGISTRER'),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required PaymentMethod? value,
    required ValueChanged<PaymentMethod?> onChanged,
  }) {
    return DropdownButtonFormField<PaymentMethod>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.account_balance_outlined),
      ),
      items: [
        PaymentMethod.cash,
        PaymentMethod.mobileMoney,
      ].map((m) => DropdownMenuItem(
        value: m,
        child: Text(m.label),
      )).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Requis' : null,
    );
  }

  Color _getOperationColor() {
    switch (widget.type) {
      case TreasuryOperationType.supply: return Colors.green;
      case TreasuryOperationType.removal: return Colors.orange;
      case TreasuryOperationType.transfer: return Colors.blue;
      case TreasuryOperationType.adjustment: return Colors.grey;
    }
  }

  String _getOperationTitle() {
    switch (widget.type) {
      case TreasuryOperationType.supply: return 'Nouvel Apport';
      case TreasuryOperationType.removal: return 'Nouveau Retrait';
      case TreasuryOperationType.transfer: return 'Nouveau Transfert';
      case TreasuryOperationType.adjustment: return 'Nouvel Ajustement';
    }
  }

  IconData _getOperationIcon() {
    switch (widget.type) {
      case TreasuryOperationType.supply: return Icons.add_circle;
      case TreasuryOperationType.removal: return Icons.remove_circle;
      case TreasuryOperationType.transfer: return Icons.swap_horiz;
      case TreasuryOperationType.adjustment: return Icons.tune;
    }
  }
}

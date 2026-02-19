import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/supplier.dart';
import '../../../../domain/entities/supplier_settlement.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../../../application/providers.dart';
import '../../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;

class SupplierSettlementDialog extends StatefulWidget {
  final Supplier supplier;

  const SupplierSettlementDialog({super.key, required this.supplier});

  @override
  State<SupplierSettlementDialog> createState() => _SupplierSettlementDialogState();
}

class _SupplierSettlementDialogState extends State<SupplierSettlementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Règlement : ${widget.supplier.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dette actuelle: ${widget.supplier.balance} CFA',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant du règlement',
                border: OutlineInputBorder(),
                suffixText: 'CFA',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                final n = int.tryParse(value);
                if (n == null || n <= 0) return 'Invalide';
                if (n > widget.supplier.balance) return 'Supérieur à la dette';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Compte de paiement',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: PaymentMethod.cash, child: Text('Caisse Espèces')),
                DropdownMenuItem(value: PaymentMethod.mobileMoney, child: Text('Mobile Money')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        Consumer(builder: (context, ref, _) {
          return ElevatedButton(
            onPressed: _isLoading ? null : () => _submit(ref),
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Valider'),
          );
        }),
      ],
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';

    final settlement = SupplierSettlement(
      id: '',
      enterpriseId: enterpriseId,
      supplierId: widget.supplier.id,
      userId: '', // Set by controller
      amount: int.parse(_amountController.text),
      paymentMethod: _paymentMethod,
      date: DateTime.now(),
      notes: _notesController.text.trim(),
    );

    try {
      await ref.read(storeControllerProvider).createSupplierSettlement(settlement);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

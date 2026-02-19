import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/supplier_settlement.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/permission_providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class SupplierSettlementDialog extends ConsumerStatefulWidget {
  const SupplierSettlementDialog({super.key, required this.purchase});
  final Purchase purchase;

  @override
  ConsumerState<SupplierSettlementDialog> createState() => _SupplierSettlementDialogState();
}

class _SupplierSettlementDialogState extends ConsumerState<SupplierSettlementDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.purchase.debtAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final supplierId = widget.purchase.supplierId;
    if (amount <= 0 || amount > widget.purchase.debtAmount) {
      NotificationService.showWarning(context, 'Montant invalide');
      return;
    }
    
    if (supplierId == null) {
      NotificationService.showError(context, 'Aucun fournisseur associé à cet achat');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? 'default';
      final userId = ref.read(currentUserIdProvider);

      final settlement = SupplierSettlement(
        id: '',
        enterpriseId: enterpriseId,
        supplierId: supplierId,
        amount: amount,
        date: DateTime.now(),
        paymentMethod: _paymentMethod,
        notes: _notesController.text,
        createdBy: userId,
      );

      await ref.read(purchaseControllerProvider).recordSupplierSettlement(
        settlement,
        purchaseId: widget.purchase.id,
      );
      
      if (mounted) {
        NotificationService.showSuccess(context, 'Règlement enregistré');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Régler la dette"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Dette restante: ${widget.purchase.debtAmount} CFA"),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: "Montant à régler", suffixText: "CFA"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(labelText: "Mode de Paiement"),
            items: const [
              DropdownMenuItem(value: PaymentMethod.cash, child: Text("Espèces")),
              DropdownMenuItem(value: PaymentMethod.mobileMoney, child: Text("Mobile Money")),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: "Notes (Optionnel)"),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
        FilledButton(onPressed: _isLoading ? null : _submit, child: const Text("ENREGISTRER")),
      ],
    );
  }
}

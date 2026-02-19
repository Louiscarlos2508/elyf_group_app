import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';

class ReceptionVerificationDialog extends ConsumerStatefulWidget {
  const ReceptionVerificationDialog({super.key, required this.purchase});
  final Purchase purchase;

  @override
  ConsumerState<ReceptionVerificationDialog> createState() => _ReceptionVerificationDialogState();
}

class _ReceptionVerificationDialogState extends ConsumerState<ReceptionVerificationDialog> {
  late List<PurchaseItem> _verifiedItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifiedItems = List.from(widget.purchase.items);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(purchaseControllerProvider).validatePurchaseOrder(
        widget.purchase.id,
        verifiedItems: _verifiedItems,
      );
      if (mounted) {
        NotificationService.showSuccess(context, 'Réception validée avec succès');
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text("Vérifier la réception ${widget.purchase.number}"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Veuillez confirmer les quantités réellement reçues pour chaque article.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...List.generate(_verifiedItems.length, (index) {
                final item = _verifiedItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Commandé: ${item.quantity} ${item.unit}", style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: item.quantity.toString(),
                          decoration: InputDecoration(
                            labelText: "Reçu (${item.unit})",
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final newQty = int.tryParse(v) ?? item.quantity;
                            setState(() {
                              _verifiedItems[index] = item.copyWith(
                                quantity: newQty,
                                totalPrice: (newQty * item.unitPrice).round(),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("ANNULER"),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? 
            const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : 
            const Text("VALIDER LA RÉCEPTION"),
        ),
      ],
    );
  }
}

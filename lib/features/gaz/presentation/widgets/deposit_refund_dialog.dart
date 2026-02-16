import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../../../core/auth/providers.dart' as auth;

class DepositRefundDialog extends ConsumerStatefulWidget {
  const DepositRefundDialog({super.key, this.siteId});

  final String? siteId;

  static Future<void> show(BuildContext context, {String? siteId}) {
    return showDialog(
      context: context,
      builder: (context) => DepositRefundDialog(siteId: siteId),
    );
  }

  @override
  ConsumerState<DepositRefundDialog> createState() => _DepositRefundDialogState();
}

class _DepositRefundDialogState extends ConsumerState<DepositRefundDialog> {
  final _formKey = GlobalKey<FormState>();
  Cylinder? _selectedCylinder;
  final _quantityController = TextEditingController(text: '1');
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
    final settingsAsync = ref.watch(gazSettingsControllerProvider);

    return AlertDialog(
      title: const Text('Retour Bouteille & Remboursement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Utilisez ce formulaire pour enregistrer le retour d\'une bouteille vide et le remboursement de sa consigne.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.md),
              cylindersAsync.when(
                data: (cylinders) => DropdownButtonFormField<Cylinder>(
                  value: _selectedCylinder,
                  decoration: const InputDecoration(
                    labelText: 'Type de bouteille',
                    border: OutlineInputBorder(),
                  ),
                  items: cylinders.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.label} (${c.weight}kg)'),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCylinder = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur cylinders: $e'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité rendue',
                  border: OutlineInputBorder(),
                  suffixText: 'unités',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Invalide';
                  return null;
                },
              ),
              if (_selectedCylinder != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FutureBuilder(
                  future: ref.read(gazSettingsControllerProvider).getSettings(enterpriseId: enterpriseId, moduleId: 'gaz'),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final rate = snapshot.data!.getDepositRate(_selectedCylinder!.weight);
                      final qty = int.tryParse(_quantityController.text) ?? 0;
                      final total = rate * qty;
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Montant à rembourser:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              CurrencyFormatter.format(total.toInt()),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Rembourser'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCylinder == null) return;

    setState(() => _isLoading = true);

    try {
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? '';
      final userId = ref.read(auth.currentUserIdProvider) ?? '';
      
      await ref.read(cylinderStockControllerProvider).refundDeposit(
        enterpriseId: enterpriseId,
        cylinderId: _selectedCylinder!.id,
        weight: _selectedCylinder!.weight,
        quantity: int.parse(_quantityController.text),
        userId: userId,
        siteId: widget.siteId,
      );

      if (mounted) {
        NotificationService.showSuccess(context, 'Retour et remboursement enregistrés');
        Navigator.pop(context);
        ref.invalidate(cylinderStocksProvider);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

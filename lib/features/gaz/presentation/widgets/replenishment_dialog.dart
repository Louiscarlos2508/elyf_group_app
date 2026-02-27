import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../../../core/auth/providers.dart' as auth;

class ReplenishmentDialog extends ConsumerStatefulWidget {
  const ReplenishmentDialog({super.key, this.siteId});

  final String? siteId;

  static Future<void> show(BuildContext context, {String? siteId}) {
    return showDialog(
      context: context,
      builder: (context) => ReplenishmentDialog(siteId: siteId),
    );
  }

  @override
  ConsumerState<ReplenishmentDialog> createState() => _ReplenishmentDialogState();
}

class _ReplenishmentDialogState extends ConsumerState<ReplenishmentDialog> {
  final _formKey = GlobalKey<FormState>();
  Cylinder? _selectedCylinder;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _leakQuantityController = TextEditingController(text: '0'); // Quantité de fuites échangées
  final _supplierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _leakQuantityController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_unitPriceController.text) ?? 0.0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
    final cylindersAsync = ref.watch(cylindersProvider);
    final stocksAsync = ref.watch(cylinderStocksProvider((
      enterpriseId: enterpriseId,
      siteId: widget.siteId,
      status: null,
    )));

    // Calculate available capacity if motherboard
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPos = activeEnterprise?.isPointOfSale ?? false;
    // No longer checking available capacity based on nominal stock

    return AlertDialog(
      title: const Text('Réception de Stock (Plein)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              cylindersAsync.when(
                data: (cylinders) => DropdownButtonFormField<Cylinder>(
                  initialValue: _selectedCylinder,
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
                  labelText: 'Quantité achetée (Plein)',
                  border: OutlineInputBorder(),
                  suffixText: 'unités',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final qty = int.tryParse(v);
                  if (qty == null || qty <= 0) return 'Invalide';
                  // No longer enforcing a strict nominal limit for stock additions
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _leakQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de fuites échangées (Gratuit)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.leak_add, color: Colors.orange),
                  suffixText: 'unités',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis (mettez 0 si aucune)';
                  if (int.tryParse(v) == null || int.parse(v) < 0) return 'Invalide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix d\'achat unitaire',
                  border: OutlineInputBorder(),
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v) == null || double.parse(v) < 0) return 'Invalide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur / Centre d\'emplissage',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Dépense:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyFormatter.format(_totalAmount.toInt()),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
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
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Enregistrer'),
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
      
      await ref.read(cylinderStockControllerProvider).replenishStock(
        enterpriseId: enterpriseId,
        cylinderId: _selectedCylinder!.id,
        weight: _selectedCylinder!.weight,
        quantity: int.parse(_quantityController.text),
        unitCost: double.parse(_unitPriceController.text),
        userId: userId,
        leakySwappedQuantity: int.parse(_leakQuantityController.text),
        siteId: widget.siteId,
        supplierName: _supplierController.text.isNotEmpty ? _supplierController.text : null,
      );

      if (mounted) {
        NotificationService.showSuccess(context, 'Réapprovisionnement enregistré avec succès');
        Navigator.pop(context);
        // Refresh stocks
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

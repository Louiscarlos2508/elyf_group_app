import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../domain/entities/product.dart';
import '../../../../shared/utils/notification_service.dart';
import '../../../../core/tenant/tenant_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _supplyUnitController;
  late TextEditingController _unitsPerLotController;
  late TextEditingController _descriptionController;
  late ProductType _type;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _priceController = TextEditingController(text: widget.product?.unitPrice.toString());
    _unitController = TextEditingController(text: widget.product?.unit ?? 'Unité');
    _supplyUnitController = TextEditingController(text: widget.product?.supplyUnit ?? 'Lot');
    _unitsPerLotController = TextEditingController(text: widget.product?.unitsPerLot.toString() ?? '1');
    _descriptionController = TextEditingController(text: widget.product?.description);
    _type = widget.product?.type ?? ProductType.finishedGood;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _supplyUnitController.dispose();
    _unitsPerLotController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? '';
      final product = Product(
        id: widget.product?.id ?? '',
        enterpriseId: enterpriseId,
        name: _nameController.text.trim(),
        type: _type,
        unitPrice: int.tryParse(_priceController.text) ?? 0,
        unit: _unitController.text.trim(),
        supplyUnit: _type == ProductType.rawMaterial ? _supplyUnitController.text.trim() : null,
        unitsPerLot: _type == ProductType.rawMaterial ? (int.tryParse(_unitsPerLotController.text) ?? 1) : 1,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      final controller = ref.read(productControllerProvider);
      if (widget.product == null) {
        await controller.createProduct(product);
      } else {
        await controller.updateProduct(product);
      }

      ref.invalidate(productsProvider);
      if (mounted) {
        Navigator.pop(context, true);
        NotificationService.showSuccess(
          context,
          widget.product == null ? "Produit créé avec succès" : "Produit mis à jour",
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.product != null;

    return AlertDialog(
      title: Text(isEdit ? "Modifier Produit" : "Nouveau Produit"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ProductType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: "Type de Produit"),
                items: ProductType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t == ProductType.rawMaterial ? "Matière Première" : "Produit Fini"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom du Produit"),
                validator: (v) => v?.isEmpty ?? true ? "Requis" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Prix Unitaire (CFA)"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? "Requis" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: "Unité"),
                      validator: (v) => v?.isEmpty ?? true ? "Requis" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_type == ProductType.rawMaterial) ...[
                const Divider(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Conversion (Aprovisionnement vs Production)",
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _supplyUnitController,
                        decoration: const InputDecoration(
                          labelText: "Unité d'achat",
                          hintText: "ex: Paquet, Rouleau",
                        ),
                        validator: (v) => _type == ProductType.rawMaterial && (v?.isEmpty ?? true) ? "Requis" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitsPerLotController,
                        decoration: const InputDecoration(
                          labelText: "Qté / Lot",
                          hintText: "ex: 100",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (_type != ProductType.rawMaterial) return null;
                          if (v == null || v.isEmpty) return "Requis";
                          if (int.tryParse(v) == null || int.parse(v) <= 0) return "Invalide";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Indiquez combien d'unités de production (ex: films) contient une unité d'achat (ex: rouleau).",
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description (Optionnel)"),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ANNULER"),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? "ENREGISTRER" : "CRÉER"),
        ),
      ],
    );
  }
}

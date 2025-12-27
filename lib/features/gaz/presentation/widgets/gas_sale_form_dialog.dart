import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import 'gas_sale_form/customer_info_widget.dart';
import 'gas_sale_form/cylinder_selector_widget.dart';
import 'gas_sale_form/gas_sale_submit_handler.dart';
import 'gas_sale_form/quantity_and_total_widget.dart';

/// Dialog de formulaire pour créer une vente de gaz.
class GasSaleFormDialog extends ConsumerStatefulWidget {
  const GasSaleFormDialog({
    super.key,
    required this.saleType,
  });

  final SaleType saleType;

  @override
  ConsumerState<GasSaleFormDialog> createState() =>
      _GasSaleFormDialogState();
}

class _GasSaleFormDialogState extends ConsumerState<GasSaleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  Cylinder? _selectedCylinder;
  int _availableStock = 0;
  bool _isLoading = false;
  String? _enterpriseId;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    if (_selectedCylinder == null) return 0.0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return _selectedCylinder!.sellPrice * quantity;
  }

  Future<void> _updateAvailableStock() async {
    if (_selectedCylinder == null || _enterpriseId == null) {
      setState(() => _availableStock = 0);
      return;
    }

    try {
      final controller = ref.read(cylinderStockControllerProvider);
      _availableStock = await controller.getAvailableStock(
        _enterpriseId!,
        _selectedCylinder!.weight,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _availableStock = 0);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCylinder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une bouteille'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    await GasSaleSubmitHandler.submit(
      context: context,
      ref: ref,
      selectedCylinder: _selectedCylinder!,
      quantity: quantity,
      availableStock: _availableStock,
      enterpriseId: _enterpriseId!,
      saleType: widget.saleType,
      customerName: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      totalAmount: _totalAmount,
      onLoadingChanged: () => setState(() => _isLoading = !_isLoading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    try {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.saleType == SaleType.retail
                                ? 'Vente au Détail'
                                : 'Vente en Gros',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Sélection de la bouteille
                    CylinderSelectorWidget(
                      selectedCylinder: _selectedCylinder,
                      onCylinderChanged: (value) {
                        setState(() {
                          _selectedCylinder = value;
                          _updateAvailableStock();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Quantité et total
                    QuantityAndTotalWidget(
                      quantityController: _quantityController,
                      selectedCylinder: _selectedCylinder,
                      availableStock: _availableStock,
                      onQuantityChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // Informations client
                    CustomerInfoWidget(
                      customerNameController: _customerNameController,
                      customerPhoneController: _customerPhoneController,
                      notesController: _notesController,
                    ),
                    const SizedBox(height: 24),
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: GazButtonStyles.outlined,
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            style: GazButtonStyles.filledPrimary,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Enregistrer la vente'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: GazButtonStyles.filledPrimary,
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

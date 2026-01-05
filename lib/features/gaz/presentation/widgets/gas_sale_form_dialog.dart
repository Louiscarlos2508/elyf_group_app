import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tenant/tenant_provider.dart';
import '../../../../shared/presentation/widgets/form_dialog_actions.dart';
import '../../../../shared/presentation/widgets/form_dialog_header.dart';
import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/tour.dart';
import 'gas_sale_form/customer_info_widget.dart';
import 'gas_sale_form/cylinder_selector_widget.dart';
import 'gas_sale_form/gas_sale_submit_handler.dart';
import 'gas_sale_form/price_stock_manager.dart';
import 'gas_sale_form/quantity_and_total_widget.dart';
import 'gas_sale_form/tour_wholesaler_selector_widget.dart';

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
  Tour? _selectedTour;
  String? _selectedWholesalerId;
  String? _selectedWholesalerName;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialiser le prix unitaire si un cylinder est déjà sélectionné
    // Note: enterpriseId sera récupéré dans le build via le provider
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _unitPrice = 0.0;

  double get _totalAmount {
    if (_selectedCylinder == null) return 0.0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return _unitPrice * quantity;
  }

  Future<void> _updateUnitPrice(String? enterpriseId) async {
    if (enterpriseId == null) return;
    final price = await PriceStockManager.updateUnitPrice(
      ref: ref,
      cylinder: _selectedCylinder,
      enterpriseId: enterpriseId,
      isWholesale: widget.saleType == SaleType.wholesale,
    );
    if (mounted) {
      setState(() => _unitPrice = price);
    }
  }

  Future<void> _updateAvailableStock(String? enterpriseId) async {
    if (enterpriseId == null) return;
    final stock = await PriceStockManager.updateAvailableStock(
      ref: ref,
      cylinder: _selectedCylinder,
      enterpriseId: enterpriseId,
    );
    if (mounted) {
      setState(() => _availableStock = stock);
    }
  }

  Future<void> _submit(String? enterpriseId) async {
    if (!_formKey.currentState!.validate()) return;
    if (enterpriseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune entreprise sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
      enterpriseId: enterpriseId,
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
      unitPrice: _unitPrice,
      tourId: widget.saleType == SaleType.wholesale ? _selectedTour?.id : null,
      wholesalerId:
          widget.saleType == SaleType.wholesale ? _selectedWholesalerId : null,
      wholesalerName: widget.saleType == SaleType.wholesale
          ? _selectedWholesalerName
          : null,
      onLoadingChanged: () => setState(() => _isLoading = !_isLoading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    // Récupérer l'ID de l'entreprise active
    final enterpriseId = activeEnterpriseAsync.when(
      data: (enterprise) => enterprise?.id,
      loading: () => null,
      error: (_, __) => null,
    );

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
                    FormDialogHeader(
                      title: widget.saleType == SaleType.retail
                          ? 'Vente au Détail'
                          : 'Vente en Gros',
                    ),
                    const SizedBox(height: 24),
                    // Sélection du tour et grossiste (uniquement pour ventes en gros)
                    if (widget.saleType == SaleType.wholesale && enterpriseId != null)
                      TourWholesalerSelectorWidget(
                        selectedTour: _selectedTour,
                        selectedWholesalerId: _selectedWholesalerId,
                        selectedWholesalerName: _selectedWholesalerName,
                        enterpriseId: enterpriseId,
                        onTourChanged: (tour) {
                          setState(() {
                            _selectedTour = tour;
                            _selectedWholesalerId = null;
                            _selectedWholesalerName = null;
                          });
                        },
                        onWholesalerChanged: (wholesaler) {
                          setState(() {
                            if (wholesaler != null) {
                              _selectedWholesalerId = wholesaler.id;
                              _selectedWholesalerName = wholesaler.name;
                            } else {
                              _selectedWholesalerId = null;
                              _selectedWholesalerName = null;
                            }
                          });
                        },
                      ),
                    if (widget.saleType == SaleType.wholesale)
                      const SizedBox(height: 16),
                    // Sélection de la bouteille
                    CylinderSelectorWidget(
                      selectedCylinder: _selectedCylinder,
                      onCylinderChanged: (value) {
                        setState(() {
                          _selectedCylinder = value;
                          if (enterpriseId != null) {
                            _updateAvailableStock(enterpriseId);
                            _updateUnitPrice(enterpriseId);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Quantité et total
                    QuantityAndTotalWidget(
                      quantityController: _quantityController,
                      selectedCylinder: _selectedCylinder,
                      availableStock: _availableStock,
                      unitPrice: _unitPrice,
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
                    FormDialogActions(
                      onCancel: () => Navigator.of(context).pop(),
                      onSubmit: () => _submit(enterpriseId),
                      submitLabel: 'Enregistrer la vente',
                      isLoading: _isLoading,
                      submitEnabled: !_isLoading && enterpriseId != null,
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

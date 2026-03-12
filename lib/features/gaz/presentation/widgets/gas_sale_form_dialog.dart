import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'gas_sale_form/customer_info_widget.dart';
import 'gas_sale_form/cylinder_selector_widget.dart';
import 'gas_sale_form/quantity_and_total_widget.dart';
import 'gas_sale_form/tour_wholesaler_selector_widget.dart';
import 'gas_print_receipt_button.dart';
import 'gas_sale_form/gas_sale_form_controller.dart';

/// Dialog de formulaire pour créer une vente de gaz.
class GasSaleFormDialog extends ConsumerStatefulWidget {
  const GasSaleFormDialog({
    super.key,
    required this.saleType,
    this.initialCylinder,
  });

  final SaleType saleType;
  final Cylinder? initialCylinder;
  @override
  ConsumerState<GasSaleFormDialog> createState() => _GasSaleFormDialogState();
}

class _GasSaleFormDialogState extends ConsumerState<GasSaleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _cashAmountController = TextEditingController();
  final _mobileAmountController = TextEditingController();
  final _unitPriceController = TextEditingController(text: '0');

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _quantityController.addListener(_onQuantityChanged);
    _unitPriceController.addListener(_onUnitPriceChanged);
  }

  void _onQuantityChanged() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    ref.read(gasSaleFormControllerProvider(widget.saleType).notifier).updateQuantity(qty);
  }

  void _onUnitPriceChanged() {
    final price = double.tryParse(_unitPriceController.text) ?? 0.0;
    ref.read(gasSaleFormControllerProvider(widget.saleType).notifier).updateUnitPrice(price);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _unitPriceController.removeListener(_onUnitPriceChanged);
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _cashAmountController.dispose();
    _mobileAmountController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit(String? enterpriseId) async {
    if (!_formKey.currentState!.validate()) return;
    if (enterpriseId == null) {
      NotificationService.showError(context, 'Aucune entreprise sélectionnée');
      return;
    }

    final notifier = ref.read(gasSaleFormControllerProvider(widget.saleType).notifier);
    
    await notifier.submit(
      context: context,
      enterpriseId: enterpriseId,
      customerName: _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      cashAmount: double.tryParse(_cashAmountController.text),
      mobileMoneyAmount: double.tryParse(_mobileAmountController.text),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);

    // Récupérer l'ID de l'entreprise active
  // Puisque les stocks sont gérés indépendamment pour chaque POS, nous utilisons l'ID direct.
  final enterpriseId = activeEnterpriseAsync.when(
    data: (enterprise) => enterprise?.id,
    loading: () => null,
    error: (_, __) => null,
  );

    final state = ref.watch(gasSaleFormControllerProvider(widget.saleType));
    final notifier = ref.read(gasSaleFormControllerProvider(widget.saleType).notifier);

    // Initialisation automatique du prix et du stock si un cylinder est pré-sélectionné
    if (!_isInitialized && enterpriseId != null) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.initialize(widget.initialCylinder, enterpriseId);
      });
    }

    // Mise à jour synchrone du prix (uniquement si le controller est à 0 et qu'on a un prix en state)
    if (_unitPriceController.text == '0' && state.unitPrice != 0) {
      _unitPriceController.text = state.unitPrice.toString();
    }

    try {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
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
                    if (widget.saleType == SaleType.wholesale &&
                        enterpriseId != null)
                      TourWholesalerSelectorWidget(
                        selectedWholesalerId: state.wholesalerId,
                        selectedWholesalerName: state.wholesalerName,
                        enterpriseId: enterpriseId,
                        onWholesalerChanged: (wholesaler) {
                          notifier.updateWholesaler(
                            wholesaler?.id,
                            wholesaler?.name,
                            enterpriseId,
                          );
                        },
                      ),

                    if (widget.saleType == SaleType.wholesale)
                      const SizedBox(height: 16),
                    // Sélection de la bouteille
                    CylinderSelectorWidget(
                      selectedCylinder: state.selectedCylinder,
                      onCylinderChanged: (value) {
                        notifier.updateCylinder(value, enterpriseId);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Quantité et total
                    QuantityAndTotalWidget(
                      quantityController: _quantityController,
                      unitPriceController: _unitPriceController,
                      selectedCylinder: state.selectedCylinder,
                      availableStock: state.availableStock,
                      onQuantityOrPriceChanged: () {
                         // Les listeners s'occupent de mettre à jour le notifier
                      },
                    ),
                    const SizedBox(height: 16),
                    // Sélecteur méthode de paiement
                    _PaymentMethodSelector(
                      selected: state.paymentMethod,
                      isMixed: state.isMixedPayment,
                      onChanged: notifier.updatePaymentMethod,
                    ),
                    if (state.isMixedPayment) ...[
                      const SizedBox(height: 12),
                      _MixedPaymentFields(
                        cashController: _cashAmountController,
                        mobileController: _mobileAmountController,
                        totalAmount: state.totalAmount,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Afficher les options avancées (Client, Notes)
                    if (widget.saleType == SaleType.retail) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: notifier.toggleAdvancedOptions,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                state.showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.showAdvancedOptions ? 'Moins d\'options' : 'Plus d\'options (Client, Notes...)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (state.showAdvancedOptions) ...[
                        const SizedBox(height: 12),
                        CustomerInfoWidget(
                          customerNameController: _customerNameController,
                          customerPhoneController: _customerPhoneController,
                          notesController: _notesController,
                          isRequired: false,
                        ),
                      ],
                    ] else ...[
                      // Wholesale: Cacher les champs client redondants (gérés par le grossiste)
                      const SizedBox(height: 16),
                      CustomerInfoWidget(
                        customerNameController: _customerNameController,
                        customerPhoneController: _customerPhoneController,
                        notesController: _notesController,
                        isRequired: false,
                        showCustomerFields: false,
                      ),
                    ],
                    if (state.completedSale != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.elasticOut,
                                    tween: Tween(begin: 0, end: 1),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          color: theme.colorScheme.primary,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Vente enregistrée avec succès',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GasPrintReceiptButton(
                              sale: state.completedSale!,
                              cylinderLabel: state.selectedCylinder?.label,
                              onPrintSuccess: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      FormDialogActions(
                        onCancel: () => Navigator.of(context).pop(),
                        onSubmit: () => _submit(enterpriseId),
                        submitLabel: 'Enregistrer la vente',
                        isLoading: state.isLoading,
                        submitEnabled: !state.isLoading && enterpriseId != null,
                      ),
                    ],
                  ],
                ),
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
              ElyfButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    }
  }

}


// ─────────────────────────────────────────────────────────────────────────────
// Sélecteur méthode de paiement
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.isMixed,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final bool isMixed;
  final void Function(PaymentMethod method, bool isMixed) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode de paiement', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'cash',
              label: Text('Espèces'),
              icon: Icon(Icons.payments_outlined, size: 16),
            ),
            ButtonSegment(
              value: 'mobileMoney',
              label: Text('Orange Money'),
              icon: Icon(Icons.account_balance_wallet_outlined, size: 16),
            ),
            ButtonSegment(
              value: 'mixed',
              label: Text('Mixte'),
              icon: Icon(Icons.shuffle, size: 16),
            ),
          ],
          selected: {isMixed ? 'mixed' : selected.name},
          onSelectionChanged: (s) {
            final val = s.first;
            if (val == 'mixed') {
              onChanged(PaymentMethod.both, true);
            } else {
              onChanged(PaymentMethod.values.byName(val), false);
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Champs de paiement mixte
// ─────────────────────────────────────────────────────────────────────────────

class _MixedPaymentFields extends StatelessWidget {
  const _MixedPaymentFields({
    required this.cashController,
    required this.mobileController,
    required this.totalAmount,
  });

  final TextEditingController cashController;
  final TextEditingController mobileController;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Total: ${totalAmount.toStringAsFixed(0)} CFA',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: cashController,
                  decoration: InputDecoration(
                    labelText: 'Part Espèces (CFA)',
                    prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: mobileController,
                  decoration: InputDecoration(
                    labelText: 'Part Orange Money (CFA)',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


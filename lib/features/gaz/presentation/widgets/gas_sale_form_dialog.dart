import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_settings.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_calculation_service.dart';
import 'gas_sale_form/customer_info_widget.dart';
import 'gas_sale_form/cylinder_selector_widget.dart';
import 'gas_sale_form/gas_sale_submit_handler.dart';
import 'gas_sale_form/price_stock_manager.dart';
import 'gas_sale_form/quantity_and_total_widget.dart';
import 'gas_sale_form/tour_wholesaler_selector_widget.dart';
import 'gas_print_receipt_button.dart';
import '../../application/providers.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
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

  Cylinder? _selectedCylinder;
  int _availableStock = 0;
  bool _isLoading = false;
  String? _selectedWholesalerId;
  String? _selectedWholesalerName;
  GasSale? _completedSale;
  bool _emptyReturned = true; // Par défaut, on suppose qu'un client rend une bouteille (échange standard)
  String _selectedTier = 'default';
  final PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isInitialized = false;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _selectedCylinder = widget.initialCylinder;
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
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    
    // Calculer la part de consigne si c'est une nouvelle bouteille
    double depositPart = 0;
    if (!_emptyReturned && _selectedCylinder != null) {
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id;
      if (enterpriseId != null) {
        final settings = ref.read(gazSettingsProvider((enterpriseId: enterpriseId, moduleId: 'gaz'))).value;
        if (settings is GazSettings) {
          depositPart = settings.getDepositRate(_selectedCylinder!.weight) * quantity;
        }
      }
    }

    return GazCalculationService.calculateTotalAmount(
      cylinder: _selectedCylinder,
      unitPrice: _unitPrice,
      quantity: quantity,
    ) + depositPart;
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
      NotificationService.showError(context, 'Aucune entreprise sélectionnée');
      return;
    }
    if (_selectedCylinder == null) {
      NotificationService.showError(
        context,
        'Veuillez sélectionner une bouteille',
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    final sale = await GasSaleSubmitHandler.submit(
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
      tourId: null,
      wholesalerId: widget.saleType == SaleType.wholesale
          ? _selectedWholesalerId
          : null,
      wholesalerName: widget.saleType == SaleType.wholesale
          ? _selectedWholesalerName
          : null,
      emptyReturnedQuantity: _emptyReturned ? (int.tryParse(_quantityController.text) ?? 0) : 0,
      dealType: _emptyReturned ? GasSaleDealType.exchange : GasSaleDealType.newCylinder,
      paymentMethod: _selectedPaymentMethod,
      onLoadingChanged: () => setState(() => _isLoading = true),
    );

    if (sale != null && mounted) {
      HapticFeedback.heavyImpact();
      setState(() => _completedSale = sale);
      
      // Auto-print logic (Story 2.4)
      try {
        final settingsAsync = ref.read(gazSettingsProvider((
          enterpriseId: enterpriseId,
          moduleId: 'gaz',
        )));
        
        settingsAsync.whenData((settings) async {
          if (settings is GazSettings && settings.autoPrintReceipt == true) {
            final printingService = ref.read(gazPrintingServiceProvider);
            final enterpriseName = ref.read(activeEnterpriseProvider).value?.name;
            
            await printingService.printSaleReceipt(
              sale: sale,
              cylinderLabel: _selectedCylinder?.label,
              enterpriseName: enterpriseName,
            );
          }
        });
      } catch (e) {
        AppLogger.error('Failed to auto-print receipt', error: e);
      }
    }
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

    // Initialisation automatique du prix et du stock si un cylinder est pré-sélectionné
    if (!_isInitialized && enterpriseId != null && _selectedCylinder != null) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateUnitPrice(enterpriseId);
        _updateAvailableStock(enterpriseId);
      });
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
                        selectedWholesalerId: _selectedWholesalerId,
                        selectedWholesalerName: _selectedWholesalerName,
                        enterpriseId: enterpriseId,
                        onWholesalerChanged: (wholesaler) {
                          setState(() {
                            if (wholesaler != null) {
                              _selectedWholesalerId = wholesaler.id;
                              _selectedWholesalerName = wholesaler.name;
                              _selectedTier = wholesaler.tier;
                              _updateUnitPrice(enterpriseId);
                            } else {
                              _selectedWholesalerId = null;
                              _selectedWholesalerName = null;
                              _selectedTier = 'default';
                              _updateUnitPrice(enterpriseId);
                            }
                          });
                        },
                      ),
                    if (widget.saleType == SaleType.wholesale) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTier,
                        decoration: const InputDecoration(
                          labelText: 'Tier de prix *',
                          prefixIcon: Icon(Icons.loyalty),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'default', child: Text('Standard')),
                          DropdownMenuItem(value: 'bronze', child: Text('Bronze')),
                          DropdownMenuItem(value: 'silver', child: Text('Silver')),
                          DropdownMenuItem(value: 'gold', child: Text('Gold')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTier = value;
                              _updateUnitPrice(enterpriseId);
                            });
                          }
                        },
                      ),
                    ],
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
                      emptyReturned: _emptyReturned,
                      onEmptyReturnedChanged: (value) =>
                          setState(() => _emptyReturned = value),
                    ),
                    if (!_emptyReturned && _selectedCylinder != null) ...[
                      const SizedBox(height: 8),
                      _DepositInfoRow(
                        weight: _selectedCylinder!.weight,
                        quantity: int.tryParse(_quantityController.text) ?? 0,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Afficher les options avancées (Client, Notes)
                    if (widget.saleType == SaleType.retail) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showAdvancedOptions ? 'Moins d\'options' : 'Plus d\'options (Client, Notes...)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showAdvancedOptions) ...[
                        const SizedBox(height: 12),
                        CustomerInfoWidget(
                          customerNameController: _customerNameController,
                          customerPhoneController: _customerPhoneController,
                          notesController: _notesController,
                          isRequired: false,
                        ),
                      ],
                    ] else ...[
                      // Wholesale: Toujours afficher les infos client
                      const SizedBox(height: 16),
                      CustomerInfoWidget(
                        customerNameController: _customerNameController,
                        customerPhoneController: _customerPhoneController,
                        notesController: _notesController,
                        isRequired: true,
                      ),
                    ],
                    if (_completedSale != null) ...[
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
                              sale: _completedSale!,
                              cylinderLabel: _selectedCylinder?.label,
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
                        isLoading: _isLoading,
                        submitEnabled: !_isLoading && enterpriseId != null,
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

  Widget _buildPOSSelectionRequiredView(ThemeData theme, Enterprise currentEnterprise) {
    final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Point de Vente Requis',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Les ventes au détail doivent être effectuées depuis un Point de Vente (POS). Vous êtes actuellement sur "${currentEnterprise.name}".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            accessibleEnterprisesAsync.when(
              data: (enterprises) {
                final posList = enterprises.where((e) => 
                  e.type == EnterpriseType.gasPointOfSale && 
                  (e.parentEnterpriseId == currentEnterprise.id || 
                   currentEnterprise.type == EnterpriseType.group ||
                   e.ancestorIds.contains(currentEnterprise.id))
                ).toList();

                if (posList.isEmpty) {
                  return Column(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun point de vente Gaz accessible trouvé pour cette entreprise.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélectionnez un Point de Vente :',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: posList.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final pos = posList[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(Icons.location_on_outlined, 
                                size: 20, color: theme.colorScheme.onPrimaryContainer),
                            ),
                            title: Text(pos.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(pos.address ?? 'Pas d\'adresse', maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () async {
                              final notifier = ref.read(activeEnterpriseIdProvider.notifier);
                              await notifier.setActiveEnterpriseId(pos.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepositInfoRow extends ConsumerWidget {
  const _DepositInfoRow({required this.weight, required this.quantity});
  final int weight;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id;
    if (enterpriseId == null) return const SizedBox.shrink();

    final settingsAsync = ref.watch(gazSettingsProvider((enterpriseId: enterpriseId, moduleId: 'gaz')));

    return settingsAsync.when(
      data: (settings) {
        final rate = settings?.getDepositRate(weight) ?? 0.0;
        if (rate <= 0) return const SizedBox.shrink();
        
        final totalDeposit = rate * quantity;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Inclut ${totalDeposit.toStringAsFixed(0)} FCFA de consigne (${rate.toStringAsFixed(0)} x $quantity)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

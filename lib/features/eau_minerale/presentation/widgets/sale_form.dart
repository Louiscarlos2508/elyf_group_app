import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/offline/offline_repository.dart';
import 'sale_product_selector.dart';
import 'sale_customer_selector.dart';

/// Form for creating/editing a sale record.
class SaleForm extends ConsumerStatefulWidget {
  const SaleForm({super.key, this.initialSale});

  final Sale? initialSale;

  @override
  ConsumerState<SaleForm> createState() => SaleFormState();
}

class SaleFormState extends ConsumerState<SaleForm> with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();
  final _phoneFocusNode = FocusNode();

  Product? _selectedProduct;
  CustomerSummary? _selectedCustomer;
  int _cashAmount = 0;
  int _orangeMoneyAmount = 0;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _showNewCustomerFields = false;
  bool _isInitialProductSelected = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSale != null) {
      _populateFromSale(widget.initialSale!);
    } else {
      _loadInitialData();
    }
  }

  void _populateFromSale(Sale sale) {
    _selectedProduct = Product(
      id: sale.productId,
      name: sale.productName,
      type: ProductType.finishedGood,
      unitPrice: sale.unitPrice,
      unit: 'unité',
      enterpriseId: sale.enterpriseId,
      createdAt: sale.date,
      updatedAt: sale.date,
    );
    
    _customerNameController.text = sale.customerName;
    _customerPhoneController.text = sale.customerPhone;
    _quantityController.text = sale.quantity.toString();
    _unitPriceController.text = sale.unitPrice.toString();
    _amountPaidController.text = sale.amountPaid.toString();
    _notesController.text = sale.notes ?? '';
    
    _cashAmount = sale.cashAmount;
    _orangeMoneyAmount = sale.orangeMoneyAmount;
    
    if (sale.cashAmount > 0 && sale.orangeMoneyAmount > 0) {
      _paymentMethod = PaymentMethod.both;
    } else if (sale.orangeMoneyAmount > 0) {
      _paymentMethod = PaymentMethod.orangeMoney;
    } else {
      _paymentMethod = PaymentMethod.cash;
    }

    if (!sale.customerId.startsWith('anonymous')) {
      _selectedCustomer = CustomerSummary(
        id: sale.customerId,
        name: sale.customerName,
        phone: sale.customerPhone,
        totalCredit: 0,
        purchaseCount: 0,
        lastPurchaseDate: sale.date,
      );
      _showNewCustomerFields = false;
    } else {
      _selectedCustomer = null;
      _showNewCustomerFields = (sale.customerName != 'Client Anonyme');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final products = await ref.read(productsProvider.future);
      if (mounted && products.isNotEmpty && !_isInitialProductSelected) {
        final firstFinishedGood = products.firstWhere(
          (p) => p.isFinishedGood,
          orElse: () => products.first,
        );
        _handleProductSelected(firstFinishedGood);
        _isInitialProductSelected = true;
      }
    } catch (e) {
      AppLogger.error('Error loading initial products: $e');
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  int? get _unitPrice => int.tryParse(_unitPriceController.text);
  double? get _quantity => double.tryParse(_quantityController.text);
  int? get _totalPrice =>
      _unitPrice != null && _quantity != null ? (_unitPrice! * _quantity!).toInt() : null;
  int? get _amountPaid => int.tryParse(_amountPaidController.text);
  bool get _isCredit => (_totalPrice ?? 0) > (_amountPaid ?? 0);

  void _handleProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      _unitPriceController.text = product.unitPrice.toString();
      _updateTotalAndPayment();
    });
  }

  void _updateTotalAndPayment() {
    if (_totalPrice != null) {
      _amountPaidController.text = _totalPrice.toString();
      _onAmountPaidChanged(_amountPaidController.text);
    }
  }

  void _handleCustomerSelected(CustomerSummary? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _customerNameController.text = customer.name;
        _customerPhoneController.text = customer.phone;
        _showNewCustomerFields = false;
      } else {
        // "Nouveau client" signal
        _customerNameController.clear();
        _customerPhoneController.clear();
        _showNewCustomerFields = true;
      }
    });
  }

  void _onPaymentMethodChanged(PaymentMethod? method) {
    if (method != null) {
      setState(() {
        _paymentMethod = method;
        if (method == PaymentMethod.cash) {
          _cashAmount = _amountPaid ?? 0;
          _orangeMoneyAmount = 0;
        } else if (method == PaymentMethod.orangeMoney) {
          _cashAmount = 0;
          _orangeMoneyAmount = _amountPaid ?? 0;
        } else if (method == PaymentMethod.both) {
          // Pré-remplir avec le montant total en espèces comme point de départ
          // L'utilisateur peut ensuite ajuster la répartition dans le PaymentSplitter
          _cashAmount = _amountPaid ?? 0;
          _orangeMoneyAmount = 0;
        }
      });
    }
  }

  void _onAmountPaidChanged(String value) {
    final amount = int.tryParse(value) ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_paymentMethod == PaymentMethod.cash) {
            _cashAmount = amount;
            _orangeMoneyAmount = 0;
          } else if (_paymentMethod == PaymentMethod.orangeMoney) {
            _cashAmount = 0;
            _orangeMoneyAmount = amount;
          } else if (_paymentMethod == PaymentMethod.both) {
            // Si l'utilisateur n'a pas encore réparti manuellement (orangeMoney = 0),
            // on met tout en espèces comme point de départ par défaut.
            if (_orangeMoneyAmount == 0) {
              _cashAmount = amount;
            }
          }
        });
      }
    });
  }

  void _onSplitChanged(int cashAmount, int orangeMoneyAmount) {
    setState(() {
      _cashAmount = cashAmount;
      _orangeMoneyAmount = orangeMoneyAmount;
    });
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? helperText,
    String? hintText,
    String? errorText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      helperMaxLines: 2,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, size: 20, color: colors.primary),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error),
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildQuantityField(BuildContext context, WidgetRef ref) {
    final productStockAsync = _selectedProduct != null 
        ? ref.watch(productStockQuantityProvider(_selectedProduct!.id))
        : null;
        
    return productStockAsync != null ? productStockAsync.when(
      data: (stock) {
        final stockError = _quantity != null && stock < _quantity!;
        return TextFormField(
          controller: _quantityController,
          decoration: _buildInputDecoration(
            context,
            label: 'Quantité',
            icon: Icons.inventory_2_outlined,
            helperText: stockError
                ? 'Stock insuffisant. Disponible: $stock'
                : 'Stock disponible: $stock',
            errorText: stockError && _quantity != null
                ? 'Stock insuffisant. Disponible: $stock'
                : null,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(_updateTotalAndPayment),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final qty = double.tryParse(v);
            if (qty == null || qty <= 0) return 'Quantité invalide';
            if (qty > stock) return 'Stock insuffisant';
            return null;
          },
        );
      },
      loading: () => TextFormField(
        controller: _quantityController,
        decoration: _buildInputDecoration(
          context,
          label: 'Quantité',
          icon: Icons.inventory_2_outlined,
          helperText: 'Chargement du stock…',
        ),
        keyboardType: TextInputType.number,
        readOnly: true,
      ),
      error: (_, __) => TextFormField(
        controller: _quantityController,
        decoration: _buildInputDecoration(
          context,
          label: 'Quantité',
          icon: Icons.inventory_2_outlined,
          helperText: 'Stock indisponible',
        ),
        enabled: false,
      ),
    ) : TextFormField(
        controller: _quantityController,
        decoration: _buildInputDecoration(
          context,
          label: 'Quantité',
          icon: Icons.inventory_2_rounded,
          helperText: 'Sélectionnez d\'abord un produit',
        ),
        readOnly: true,
      );
  }

  Widget _buildUnitPriceField(BuildContext context) {
    return TextFormField(
      controller: _unitPriceController,
      decoration: _buildInputDecoration(
        context,
        label: 'Prix Unitaire (CFA)',
        icon: Icons.price_change_outlined,
        helperText: _selectedProduct != null
            ? 'Prix catalogue: ${_selectedProduct!.unitPrice} CFA'
            : 'Sélectionnez d\'abord un produit',
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(_updateTotalAndPayment),
      readOnly: _selectedProduct == null,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requis';
        final price = int.tryParse(v);
        if (price == null || price < 0) return 'Prix invalide';
        return null;
      },
    );
  }


  Future<void> submit() async {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    
    if (!formValid) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      String message = 'Veuillez corriger les erreurs en rouge';
      
      // Message plus spécifique pour le crédit
      if (_isCredit && _selectedCustomer == null) {
        if (_customerNameController.text.trim().isEmpty) {
          message = 'Nom requis pour la vente à crédit';
        }
      }

      NotificationService.showWarning(context, message);
      return;
    }

    if (_selectedProduct == null) {
      NotificationService.showWarning(
        context,
        'Veuillez sélectionner un produit',
      );
      return;
    }

    if (_totalPrice == null || _amountPaid == null) {
      NotificationService.showWarning(
        context,
        'Veuillez remplir tous les champs',
      );
      return;
    }

    // Validation du paiement mixte : la répartition doit correspondre au montant versé
    if (_paymentMethod == PaymentMethod.both) {
      final splitTotal = _cashAmount + _orangeMoneyAmount;
      if (splitTotal != _amountPaid!) {
        NotificationService.showError(
          context,
          'La répartition Cash + Orange Money ($splitTotal CFA) doit être égale au montant versé (${_amountPaid!} CFA).',
        );
        return;
      }
    }

    final saleService = ref.read(saleServiceProvider);
    final stock = await ref.read(productStockQuantityProvider(_selectedProduct!.id).future);
    final validationError = await saleService.validateSale(
      productId: _selectedProduct!.id,
      quantity: _quantity,
      totalPrice: _totalPrice,
      amountPaid: _amountPaid,
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name ?? (_customerNameController.text.isEmpty ? 'Client Anonyme' : _customerNameController.text),
      customerPhone: _selectedCustomer?.phone ?? _customerPhoneController.text,
      stockOverride: stock,
    );

    if (!mounted) return;
    if (validationError != null) {
      NotificationService.showError(context, validationError);
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (_) {}, // État de chargement géré par handleFormSubmit
      onSubmit: () async {
        // Si pas de client sélectionné mais nom renseigné, créer un nouveau client
        String customerId = _selectedCustomer?.id ?? '';
        final customerName = _selectedCustomer?.name ?? _customerNameController.text.trim();
        final rawPhone = _selectedCustomer?.phone ?? _customerPhoneController.text.trim();
        final customerPhone = rawPhone.isEmpty
            ? ''
            : (PhoneUtils.normalizeBurkina(rawPhone) ?? rawPhone);

        if (customerId.isNotEmpty && _selectedCustomer != null) {
          // Si le client existe déjà, vérifier s'il faut mettre à jour le téléphone
          final existingPhone = _selectedCustomer?.phone ?? '';
          if (customerPhone.isNotEmpty && customerPhone != existingPhone) {
            final clientsController = ref.read(clientsControllerProvider);
            await clientsController.updateCustomer(
              id: customerId,
              phone: customerPhone,
            );
          }
        } else if (customerId.isEmpty && customerName.isNotEmpty) {
          // Créer le nouveau client via le controller (logique métier dans le controller)
          final clientsController = ref.read(clientsControllerProvider);
          customerId = await clientsController.createCustomer(
            customerName,
            customerPhone,
          );
        } else if (customerId.isEmpty) {
          // Client anonyme (logique métier simple)
          customerId = 'anonymous-${DateTime.now().millisecondsSinceEpoch}';
        }

        // Utiliser SaleService pour déterminer le statut (logique métier dans le service)
        final saleStatus = saleService.determineSaleStatus(
          _totalPrice!,
          _amountPaid!,
        );

        final product = _selectedProduct!;
        final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';
        final userId = ref.read(currentUserIdProvider);

        final sale = Sale(
          id: widget.initialSale?.id ?? LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          productId: product.id,
          productName: product.name,
          quantity: _quantity!,
          unitPrice: _unitPrice!,
          totalPrice: _totalPrice!,
          amountPaid: _amountPaid!,
          customerName: customerName.isEmpty ? 'Client Anonyme' : customerName,
          customerPhone: customerPhone,
          customerId: customerId,
          date: widget.initialSale?.date ?? DateTime.now(),
          status: saleStatus,
          createdBy: widget.initialSale?.createdBy ?? userId,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          cashAmount: _cashAmount,
          orangeMoneyAmount: _orangeMoneyAmount,
          createdAt: widget.initialSale?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.initialSale != null) {
          await ref.read(salesControllerProvider).updateSale(widget.initialSale!, sale, userId);
        } else {
          await ref.read(salesControllerProvider).createSale(sale, userId);
        }

        if (mounted) {
          // Invalider les providers pour rafraîchir les données
          ref.invalidate(salesStateProvider);
          ref.invalidate(stockStateProvider);
          ref.invalidate(clientsStateProvider);
        }

        return widget.initialSale != null ? 'Vente modifiée' : 'Vente enregistrée';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._buildLeftColumn(context),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildRightColumn(context),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._buildLeftColumn(context),
                const SizedBox(height: 16),
                ..._buildRightColumn(context),
              ],
            );
          }
        },
      ),
    ),
    );
  }

  List<Widget> _buildLeftColumn(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return [
      ElyfCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Informations Client',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormField<Product?>(
              initialValue: _selectedProduct,
              validator: (v) => v == null ? 'Produit requis' : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: state.hasError
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.error, width: 2),
                            )
                          : null,
                      child: SaleProductSelector(
                        selectedProduct: _selectedProduct,
                        onProductSelected: (p) {
                          _handleProductSelected(p);
                          state.didChange(p);
                        },
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          state.errorText!,
                          style: theme.textTheme.labelSmall?.copyWith(color: colors.error),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FormField<CustomerSummary?>(
              initialValue: _selectedCustomer,
              validator: (v) {
                if (_isCredit) {
                  if (v == null && _selectedCustomer == null && _customerNameController.text.trim().isEmpty) {
                    return 'Nom requis pour le crédit';
                  }
                }
                return null;
              },
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: state.hasError
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.error, width: 2),
                            )
                          : null,
                      child: SaleCustomerSelector(
                        selectedCustomer: _selectedCustomer,
                        onCustomerSelected: (c) {
                          _handleCustomerSelected(c);
                          state.didChange(c);
                        },
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          state.errorText!,
                          style: theme.textTheme.labelSmall?.copyWith(color: colors.error),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_showNewCustomerFields || (_isCredit && _selectedCustomer == null)) ...[
              TextFormField(
                controller: _customerNameController,
                decoration: _buildInputDecoration(
                  context,
                  label: 'Nom du client${_isCredit ? ' (Requis)' : ''}',
                  icon: Icons.person_outline_rounded,
                  helperText: _isCredit ? 'Obligatoire pour le crédit' : 'Laisser vide pour client anonyme',
                ),
                validator: (v) {
                  if ((_showNewCustomerFields || _isCredit) && _selectedCustomer == null) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nom obligatoire';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerPhoneController,
                focusNode: _phoneFocusNode,
                decoration: _buildInputDecoration(
                  context,
                  label: 'Téléphone',
                  icon: Icons.phone_android_rounded,
                  hintText: '70 00 00 00',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    return Validators.phoneBurkina(v);
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildRightColumn(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return [
      ElyfCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Détails de la Vente',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildUnitPriceField(context),
            const SizedBox(height: 16),
            _buildQuantityField(context, ref),
            const SizedBox(height: 24),
            if (_totalPrice != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                   gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.8),
                      colors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL À PAYER',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatFCFA(_totalPrice!),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_totalPrice! - (_amountPaid ?? 0) > 0) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RESTE (CRÉDIT)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatFCFA(_totalPrice! - (_amountPaid ?? 0)),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            Text(
              'Mode de paiement',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.cash,
                  label: Text('Cash'),
                  icon: Icon(Icons.money_rounded, size: 18),
                ),
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.orangeMoney,
                  label: Text('Om'),
                  icon: Icon(Icons.wallet_rounded, size: 18),
                ),
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.both,
                  label: Text('Mixte'),
                  icon: Icon(Icons.compare_arrows_rounded, size: 18),
                ),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (Set<PaymentMethod> selection) {
                _onPaymentMethodChanged(selection.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: colors.primary,
                selectedForegroundColor: colors.onPrimary,
                visualDensity: VisualDensity.standard,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountPaidController,
              decoration: _buildInputDecoration(
                context,
                label: 'Montant versé (CFA)',
                icon: Icons.account_balance_wallet_rounded,
                helperText: 'Saisir le montant réellement reçu',
              ),
              keyboardType: TextInputType.number,
              onChanged: _onAmountPaidChanged,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final amount = int.tryParse(v);
                if (amount == null || amount < 0) return 'Montant invalide';
                return null;
              },
            ),
            if (_paymentMethod == PaymentMethod.both &&
                    _amountPaid != null &&
                    _amountPaid! > 0) ...[
              const SizedBox(height: 16),
              PaymentSplitter(
                totalAmount: _amountPaid!,
                onSplitChanged: _onSplitChanged,
                initialCashAmount: _cashAmount,
                initialMobileMoneyAmount: _orangeMoneyAmount,
                mobileMoneyLabel: 'Orange Money',
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: _buildInputDecoration(
                context,
                label: 'Notes (Optionnel)',
                icon: Icons.note_alt_rounded,
                hintText: 'Observations...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    ];
  }
}

enum PaymentMethod { cash, orangeMoney, both }

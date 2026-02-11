import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/pack_constants.dart';
import '../../domain/repositories/customer_repository.dart';
import 'sale_product_selector.dart';
import 'sale_customer_selector.dart';

/// Form for creating/editing a sale record.
class SaleForm extends ConsumerStatefulWidget {
  const SaleForm({super.key});

  @override
  ConsumerState<SaleForm> createState() => SaleFormState();
}

class SaleFormState extends ConsumerState<SaleForm> with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();

  Product? _selectedProduct;
  CustomerSummary? _selectedCustomer;
  int _cashAmount = 0;
  int _orangeMoneyAmount = 0;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _quantityController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _unitPrice => _selectedProduct?.unitPrice;
  int? get _quantity => int.tryParse(_quantityController.text);
  int? get _totalPrice =>
      _unitPrice != null && _quantity != null ? _unitPrice! * _quantity! : null;
  int? get _amountPaid => int.tryParse(_amountPaidController.text);
  bool get _isCredit => (_totalPrice ?? 0) > (_amountPaid ?? 0);

  void _handleProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      if (_totalPrice != null && _amountPaidController.text.isEmpty) {
        _amountPaidController.text = _totalPrice.toString();
        _cashAmount = _totalPrice!;
        _orangeMoneyAmount = 0;
      }
    });
  }

  void _handleCustomerSelected(CustomerSummary? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _customerNameController.text = customer.name;
        _customerPhoneController.text = customer.phone;
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
          // Ne pas initialiser automatiquement, laisser l'utilisateur répartir
          _cashAmount = 0;
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
          }
          // Si "Les deux", ne pas modifier automatiquement
          // L'utilisateur répartira manuellement dans PaymentSplitter
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
    final packStockAsync = ref.watch(packStockQuantityProvider);
    return packStockAsync.when(
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
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final qty = int.tryParse(v);
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
    );
  }

  Future<void> submit() async {
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

    final saleService = ref.read(saleServiceProvider);
    final packStock = _selectedProduct!.id == packProductId
        ? await ref.read(packStockQuantityProvider.future)
        : null;
    final validationError = await saleService.validateSale(
      productId: _selectedProduct!.id,
      quantity: _quantity,
      totalPrice: _totalPrice,
      amountPaid: _amountPaid,
      customerId: _selectedCustomer?.id,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      packStockOverride: packStock,
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
        final customerName = _customerNameController.text.trim();
        final rawPhone = _customerPhoneController.text.trim();
        final customerPhone = rawPhone.isEmpty
            ? ''
            : (PhoneUtils.normalizeBurkina(rawPhone) ?? rawPhone);

        if (customerId.isEmpty && customerName.isNotEmpty) {
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
        final productId = product.id == packProductId
            ? packProductId
            : product.id;
        final productName = product.id == packProductId
            ? packName
            : product.name;
        final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';

        final sale = Sale(
          id: '',
          enterpriseId: enterpriseId,
          productId: productId,
          productName: productName,
          quantity: _quantity!,
          unitPrice: _unitPrice!,
          totalPrice: _totalPrice!,
          amountPaid: _amountPaid!,
          customerName: customerName,
          customerPhone: customerPhone,
          customerId: customerId,
          customerCnib: null,
          date: DateTime.now(),
          status: saleStatus,
          createdBy: 'user-1',
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          cashAmount: _cashAmount,
          orangeMoneyAmount: _orangeMoneyAmount,
        );

        final userId = ref.read(currentUserIdProvider);

        await ref.read(salesControllerProvider).createSale(sale, userId);

        if (mounted) {
          // Invalider les providers pour rafraîchir les données
          ref.invalidate(salesStateProvider);
          ref.invalidate(stockStateProvider);
          ref.invalidate(clientsStateProvider);
        }

        return 'Vente enregistrée';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
                    children: _buildLeftColumn(context),
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
            SaleProductSelector(
              selectedProduct: _selectedProduct,
              onProductSelected: _handleProductSelected,
            ),
            const SizedBox(height: 16),
            SaleCustomerSelector(
              selectedCustomer: _selectedCustomer,
              onCustomerSelected: _handleCustomerSelected,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: _buildInputDecoration(
                context,
                label: 'Nom du client${_isCredit ? ' (Requis)' : ''}',
                icon: Icons.person_outline_rounded,
                helperText: _isCredit ? 'Obligatoire pour le crédit' : 'Laisser vide pour client anonyme',
              ),
              validator: (v) {
                if (_isCredit && (v == null || v.trim().isEmpty)) {
                  return 'Nom obligatoire pour le crédit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerPhoneController,
              decoration: _buildInputDecoration(
                context,
                label: 'Téléphone${_isCredit ? ' (Requis)' : ''}',
                icon: Icons.phone_android_rounded,
                hintText: '70 00 00 00',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (_isCredit && (v == null || v.trim().isEmpty)) {
                  return 'Téléphone obligatoire pour le crédit';
                }
                if (v != null && v.trim().isNotEmpty) {
                  return Validators.phoneBurkina(v);
                }
                return null;
              },
            ),
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
            if (_selectedProduct != null)
              _buildQuantityField(context, ref)
            else
              TextFormField(
                controller: _quantityController,
                decoration: _buildInputDecoration(
                  context,
                  label: 'Quantité',
                  icon: Icons.inventory_2_rounded,
                  helperText: 'Sélectionnez d\'abord un produit',
                ),
                readOnly: true,
              ),
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

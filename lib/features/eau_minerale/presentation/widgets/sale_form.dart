import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
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

  Widget _buildQuantityField(WidgetRef ref) {
    final packStockAsync = ref.watch(packStockQuantityProvider);
    return packStockAsync.when(
      data: (stock) {
        final stockError = _quantity != null && stock < _quantity!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité',
                prefixIcon: const Icon(Icons.inventory_2),
                helperText: stockError
                    ? 'Stock insuffisant. Disponible: $stock'
                    : 'Stock disponible: $stock',
                helperMaxLines: 2,
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
                if (qty > stock) return 'Stock insuffisant. Disponible: $stock';
                return null;
              },
            ),
          ],
        );
      },
      loading: () => TextFormField(
        controller: _quantityController,
        decoration: const InputDecoration(
          labelText: 'Quantité',
          prefixIcon: Icon(Icons.inventory_2),
          helperText: 'Chargement du stock…',
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requis';
          final qty = int.tryParse(v);
          if (qty == null || qty <= 0) return 'Quantité invalide';
          return null;
        },
      ),
      error: (_, __) => TextFormField(
        controller: _quantityController,
        decoration: const InputDecoration(
          labelText: 'Quantité',
          prefixIcon: Icon(Icons.inventory_2),
          helperText: 'Stock indisponible',
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requis';
          final qty = int.tryParse(v);
          if (qty == null || qty <= 0) return 'Quantité invalide';
          return null;
        },
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
        final sale = Sale(
          id: '',
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Produit
          SaleProductSelector(
            selectedProduct: _selectedProduct,
            onProductSelected: _handleProductSelected,
          ),
          const SizedBox(height: 16),
          // Client (optionnel)
          SaleCustomerSelector(
            selectedCustomer: _selectedCustomer,
            onCustomerSelected: _handleCustomerSelected,
          ),
          const SizedBox(height: 16),
          // Nom et téléphone (pré-remplis si client sélectionné)
          TextFormField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'Nom du client${_isCredit ? ' (Requis)' : ''}',
              prefixIcon: const Icon(Icons.person_outline),
              helperText: _isCredit ? 'Obligatoire pour une vente à crédit' : null,
              helperStyle: _isCredit ? TextStyle(color: theme.colorScheme.error) : null,
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
            decoration: InputDecoration(
              labelText: 'Téléphone${_isCredit ? ' (Requis)' : ''}',
              prefixIcon: const Icon(Icons.phone),
              hintText: '+226 70 00 00 00',
              helperText: _isCredit ? 'Obligatoire pour une vente à crédit' : null,
              helperStyle: _isCredit ? TextStyle(color: theme.colorScheme.error) : null,
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
          const SizedBox(height: 16),
          if (_selectedProduct != null)
            _buildQuantityField(ref)
          else
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                prefixIcon: Icon(Icons.inventory_2),
                helperText: 'Sélectionnez d\'abord un produit',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final qty = int.tryParse(v);
                if (qty == null || qty <= 0) return 'Quantité invalide';
                return null;
              },
            ),
          if (_totalPrice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatFCFA(_totalPrice!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Mode de paiement - SIMPLIFIÉ
          Text(
            'Mode de paiement',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment<PaymentMethod>(
                value: PaymentMethod.cash,
                label: Text('Cash'),
                icon: Icon(Icons.money),
              ),
              ButtonSegment<PaymentMethod>(
                value: PaymentMethod.orangeMoney,
                label: Text('Orange Money'),
                icon: Icon(Icons.account_balance_wallet),
              ),
              ButtonSegment<PaymentMethod>(
                value: PaymentMethod.both,
                label: Text('Les deux'),
                icon: Icon(Icons.payment),
              ),
            ],
            selected: {_paymentMethod},
            onSelectionChanged: (Set<PaymentMethod> selection) {
              _onPaymentMethodChanged(selection.first);
            },
          ),
          const SizedBox(height: 16),
          // Montant payé
          TextFormField(
            controller: _amountPaidController,
            decoration: InputDecoration(
              labelText: 'Montant payé (CFA)',
              prefixIcon: const Icon(Icons.attach_money),
              helperText: _totalPrice != null && _amountPaid != null
                  ? (_totalPrice! - _amountPaid! > 0
                        ? 'Crédit: ${CurrencyFormatter.formatFCFA(_totalPrice! - _amountPaid!)}'
                        : 'Paiement complet')
                  : null,
            ),
            keyboardType: TextInputType.number,
            onChanged: _onAmountPaidChanged,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              final amount = int.tryParse(v);
              if (amount == null || amount < 0) return 'Montant invalide';
              if (_totalPrice != null && amount > _totalPrice!) {
                return 'Ne peut pas dépasser le total';
              }
              return null;
            },
          ),
          // Répartition si les deux modes sont sélectionnés
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
          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes / Observations',
              prefixIcon: Icon(Icons.note_alt_outlined),
              hintText: 'Ex: Commande spéciale, livraison prévue le...',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

enum PaymentMethod { cash, orangeMoney, both }

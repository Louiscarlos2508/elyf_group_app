import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/sale_service.dart';
import 'sale_product_selector.dart';
import 'sale_customer_selector.dart';
import 'simple_payment_splitter.dart';

/// Form for creating/editing a sale record.
class SaleForm extends ConsumerStatefulWidget {
  const SaleForm({super.key});

  @override
  ConsumerState<SaleForm> createState() => SaleFormState();
}

class SaleFormState extends ConsumerState<SaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountPaidController = TextEditingController();
  
  Product? _selectedProduct;
  CustomerSummary? _selectedCustomer;
  bool _isLoading = false;
  int _cashAmount = 0;
  int _orangeMoneyAmount = 0;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _quantityController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  int? get _unitPrice => _selectedProduct?.unitPrice;
  int? get _quantity => int.tryParse(_quantityController.text);
  int? get _totalPrice => _unitPrice != null && _quantity != null
      ? _unitPrice! * _quantity!
      : null;
  int? get _amountPaid => int.tryParse(_amountPaidController.text);

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
          // L'utilisateur répartira manuellement dans SimplePaymentSplitter
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

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      NotificationService.showWarning(context, 'Veuillez sélectionner un produit');
      return;
    }

    if (_totalPrice == null || _amountPaid == null) {
      NotificationService.showWarning(context, 'Veuillez remplir tous les champs');
      return;
    }

    // Utiliser SaleService pour valider la vente
    final saleService = ref.read(saleServiceProvider);
    final validationError = await saleService.validateSale(
      productId: _selectedProduct!.id,
      quantity: _quantity,
      totalPrice: _totalPrice,
      amountPaid: _amountPaid,
    );
    
    if (validationError != null) {
      if (!mounted) return;
      NotificationService.showError(context, validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Si pas de client sélectionné mais nom renseigné, créer un nouveau client
      String customerId = _selectedCustomer?.id ?? '';
      final customerName = _customerNameController.text.trim();
      final customerPhone = _customerPhoneController.text.trim();
      
      if (customerId.isEmpty && customerName.isNotEmpty) {
        // Créer le nouveau client dans le repository
        final clientsController = ref.read(clientsControllerProvider);
        customerId = await clientsController.createCustomer(
          customerName,
          customerPhone,
        );
      } else if (customerId.isEmpty) {
        // Client anonyme
        customerId = 'anonymous-${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Utiliser SaleService pour déterminer le statut
      final saleStatus = saleService.determineSaleStatus(_totalPrice!, _amountPaid!);
      
      final sale = Sale(
        id: '',
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
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
        notes: null,
        cashAmount: _cashAmount,
        orangeMoneyAmount: _orangeMoneyAmount,
      );

      final userId = ref.read(currentUserIdProvider);
      
      await ref.read(salesControllerProvider).createSale(sale, userId);

      if (!mounted) return;
      // Invalider les providers pour rafraîchir les données
      ref.invalidate(salesStateProvider);
      ref.invalidate(stockStateProvider);
      ref.invalidate(clientsStateProvider);
      Navigator.of(context).pop();
      ref.invalidate(salesStateProvider);
      NotificationService.showSuccess(context, 'Vente enregistrée');
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) {
    // Utiliser CurrencyFormatter mais avec " CFA" au lieu de " FCFA" pour compatibilité
    return CurrencyFormatter.formatFCFA(amount).replaceAll(' FCFA', ' CFA');
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
              decoration: const InputDecoration(
                labelText: 'Nom du client',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // Quantité avec validation du stock
            if (_selectedProduct != null)
              FutureBuilder<int>(
                future: ref.read(saleServiceProvider).getCurrentStock(_selectedProduct!.id),
                builder: (context, snapshot) {
                  final stock = snapshot.data ?? 0;
                  final stockError = _quantity != null && stock < _quantity!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantité',
                          prefixIcon: const Icon(Icons.inventory_2),
                          helperText: snapshot.hasData
                              ? (stockError
                                  ? 'Stock insuffisant. Disponible: $stock'
                                  : 'Stock disponible: $stock')
                              : 'Vérification du stock...',
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
                          if (snapshot.hasData && qty > stock) {
                            return 'Stock insuffisant. Disponible: $stock';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                },
              )
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
                      _formatCurrency(_totalPrice!),
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
                        ? 'Crédit: ${_formatCurrency(_totalPrice! - _amountPaid!)}'
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
            if (_paymentMethod == PaymentMethod.both && _amountPaid != null && _amountPaid! > 0) ...[
              const SizedBox(height: 16),
              SimplePaymentSplitter(
                totalAmount: _amountPaid!,
                onSplitChanged: _onSplitChanged,
                initialCashAmount: _cashAmount,
                initialOrangeMoneyAmount: _orangeMoneyAmount,
              ),
            ],
          ],
        ),
    );
  }
}

enum PaymentMethod {
  cash,
  orangeMoney,
  both,
}

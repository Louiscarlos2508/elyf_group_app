import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/customer_repository.dart';
import 'sale_product_selector.dart';
import 'sale_customer_selector.dart';
import 'sale_form_fields.dart';

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
  final _customerCnibController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  Product? _selectedProduct;
  CustomerSummary? _selectedCustomer;
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerCnibController.dispose();
    _quantityController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _unitPrice => _selectedProduct?.unitPrice;
  int? get _quantity => int.tryParse(_quantityController.text);
  int? get _totalPrice => _unitPrice != null && _quantity != null
      ? _unitPrice! * _quantity!
      : null;
  int? get _amountPaid => int.tryParse(_amountPaidController.text);
  int? get _remainingAmount =>
      _totalPrice != null && _amountPaid != null
          ? _totalPrice! - _amountPaid!
          : null;

  void _handleProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      if (_amountPaidController.text.isEmpty && _totalPrice != null) {
        _amountPaidController.text = _totalPrice.toString();
      }
    });
  }

  void _handleCustomerSelected(CustomerSummary? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _customerNameController.text = customer.name;
        _customerPhoneController.text = customer.phone;
        _customerCnibController.text = customer.cnib ?? '';
      }
    });
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit')),
      );
      return;
    }

    if (_totalPrice == null || _amountPaid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (_amountPaid! > _totalPrice!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le montant payé ne peut pas dépasser le total')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sale = Sale(
        id: '',
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        quantity: _quantity!,
        unitPrice: _unitPrice!,
        totalPrice: _totalPrice!,
        amountPaid: _amountPaid!,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        customerId: _selectedCustomer?.id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
        customerCnib: _customerCnibController.text.isEmpty
            ? null
            : _customerCnibController.text.trim(),
        date: DateTime.now(),
        status: _remainingAmount == 0
            ? SaleStatus.fullyPaid
            : SaleStatus.pending,
        createdBy: 'user-1',
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(salesControllerProvider).createSale(sale);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(salesStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_remainingAmount == 0
              ? 'Vente enregistrée'
              : 'Vente enregistrée (Crédit: ${_remainingAmount} CFA)'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' CFA';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            SaleFormFields(
              customerNameController: _customerNameController,
              customerPhoneController: _customerPhoneController,
              customerCnibController: _customerCnibController,
              quantityController: _quantityController,
              amountPaidController: _amountPaidController,
              notesController: _notesController,
              selectedProduct: _selectedProduct,
              totalPrice: _totalPrice,
              remainingAmount: _remainingAmount,
              onQuantityChanged: () => setState(() {}),
              onAmountPaidChanged: () => setState(() {}),
              formatCurrency: _formatCurrency,
            ),
          ],
        ),
      ),
    );
  }
}

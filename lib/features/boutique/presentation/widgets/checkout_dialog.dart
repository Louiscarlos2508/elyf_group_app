import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/notification_service.dart';
import '../../application/providers.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/sale.dart';
import 'package:elyf_groupe_app/shared/utils/form_helper_mixin.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({
    super.key,
    required this.cartItems,
    required this.total,
    required this.onSuccess,
  });

  final List<CartItem> cartItems;
  final int total;
  final VoidCallback onSuccess;

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountPaidController = TextEditingController();
  final _customerNameController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = false;
  Sale? _completedSale;

  @override
  void initState() {
    super.initState();
    _amountPaidController.text = widget.total.toString();
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.formatFCFA(amount);
  }

  int? get _amountPaid => int.tryParse(_amountPaidController.text);
  int get _change {
    if (_amountPaid == null) return 0;
    // Utiliser le service de calcul pour extraire la logique métier
    final cartService = ref.read(cartCalculationServiceProvider);
    return cartService.calculateChange(
      amountPaid: _amountPaid!,
      total: widget.total,
    );
  }

  Future<void> _processPayment() async {
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final sale = Sale(
          id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          items: widget.cartItems.map((item) {
            return SaleItem(
              productId: item.product.id,
              productName: item.product.name,
              quantity: item.quantity,
              unitPrice: item.product.price,
              totalPrice: item.totalPrice,
            );
          }).toList(),
          totalAmount: widget.total,
          amountPaid: _amountPaid!,
          customerName: _customerNameController.text.isEmpty
              ? null
              : _customerNameController.text.trim(),
          paymentMethod: _paymentMethod,
        );

        await ref.read(storeControllerProvider).createSale(sale);

        if (mounted) {
          // Garder la vente pour l'impression
          setState(() => _completedSale = sale);
          
          ref.invalidate(recentSalesProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(lowStockProductsProvider);
        }

        // Ne pas fermer le dialog immédiatement pour permettre l'impression
        return 'Vente enregistrée avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
                          'Paiement',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total à payer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatCurrency(widget.total),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Méthode de paiement',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PaymentMethod>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentMethod.cash,
                        label: Text('Espèces'),
                        icon: Icon(Icons.money),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.mobileMoney,
                        label: Text('Mobile Money'),
                        icon: Icon(Icons.phone_android),
                      ),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (Set<PaymentMethod> newSelection) {
                      setState(() => _paymentMethod = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _amountPaidController,
                    decoration: const InputDecoration(
                      labelText: 'Montant payé (FCFA) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      final amount = int.tryParse(v);
                      if (amount == null || amount <= 0) return 'Montant invalide';
                      if (amount < widget.total && _paymentMethod == PaymentMethod.cash) {
                        return 'Montant insuffisant';
                      }
                      return null;
                    },
                  ),
                  if (_change > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monnaie à rendre',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatCurrency(_change),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du client (optionnel)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  if (_completedSale != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vente enregistrée',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PrintReceiptButton(
                            sale: _completedSale!,
                            onPrintSuccess: () {
                              Navigator.of(context).pop();
                              widget.onSuccess();
                            },
                            onPrintError: (error) {
                              // L'erreur est déjà affichée dans le SnackBar
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onSuccess();
                            },
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        IntrinsicWidth(
                          child: FilledButton(
                            onPressed: _isLoading ? null : _processPayment,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Valider le paiement'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


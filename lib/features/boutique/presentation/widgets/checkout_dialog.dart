import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/sale.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

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
  int _cashAmount = 0;
  int _mobileMoneyAmount = 0;
  int _cardAmount = 0;
  bool _isLoading = false;
  Sale? _completedSale;

  @override
  void initState() {
    super.initState();
    _amountPaidController.text = widget.total.toString();
    _cashAmount = widget.total;
    _mobileMoneyAmount = 0;
    _cardAmount = 0;
  }

  void _onPaymentMethodChanged(PaymentMethod method) {
    setState(() {
      _paymentMethod = method;
      final amountPaid = _amountPaid ?? 0;
      if (method == PaymentMethod.cash) {
        _cashAmount = amountPaid;
        _mobileMoneyAmount = 0;
        _cardAmount = 0;
      } else if (method == PaymentMethod.mobileMoney) {
        _cashAmount = 0;
        _mobileMoneyAmount = amountPaid;
        _cardAmount = 0;
      } else if (method == PaymentMethod.card) {
        _cashAmount = 0;
        _mobileMoneyAmount = 0;
        _cardAmount = amountPaid;
      } else if (method == PaymentMethod.both) {
        _cashAmount = 0;
        _mobileMoneyAmount = 0;
        _cardAmount = 0;
      }
    });
  }

  void _onAmountPaidChanged(String value) {
    final amount = int.tryParse(value) ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_paymentMethod == PaymentMethod.cash) {
            _cashAmount = amount;
            _mobileMoneyAmount = 0;
            _cardAmount = 0;
          } else if (_paymentMethod == PaymentMethod.mobileMoney) {
            _cashAmount = 0;
            _mobileMoneyAmount = amount;
            _cardAmount = 0;
          } else if (_paymentMethod == PaymentMethod.card) {
            _cashAmount = 0;
            _mobileMoneyAmount = 0;
            _cardAmount = amount;
          }
        });
      }
    });
  }

  void _onSplitChanged(int cashAmount, int mobileMoneyAmount, int cardAmount) {
    setState(() {
      _cashAmount = cashAmount;
      _mobileMoneyAmount = mobileMoneyAmount;
      _cardAmount = cardAmount;
    });
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  int? get _amountPaid => int.tryParse(_amountPaidController.text);

  Future<void> _processPayment() async {
    // Vérifier les permissions avant de traiter le paiement
    final adapter = ref.read(boutiquePermissionAdapterProvider);
    final hasUsePos = await adapter.hasPermission(
      BoutiquePermissions.usePos.id,
    );
    final hasCreateSale = await adapter.hasPermission(
      BoutiquePermissions.createSale.id,
    );

    if (!hasUsePos && !hasCreateSale) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'Vous n\'avez pas la permission d\'utiliser la caisse ou de créer une vente.',
      );
      return;
    }

    await handleFormSubmit(
      // ignore: use_build_context_synchronously - mounted checked in form helper before showing dialogs
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        // Calculer le montant payé selon la méthode
        final amountPaid = _paymentMethod == PaymentMethod.both
            ? (_cashAmount + _mobileMoneyAmount + _cardAmount)
            : (_amountPaid ?? 0);

        // Validation pour paiement mixte
        if (_paymentMethod == PaymentMethod.both) {
          if (_cashAmount + _mobileMoneyAmount + _cardAmount != widget.total) {
            throw ValidationException(
              'La somme des montants (${CurrencyFormatter.formatFCFA(_cashAmount + _mobileMoneyAmount + _cardAmount)}) doit être égale au total (${CurrencyFormatter.formatFCFA(widget.total)})',
              'PAYMENT_AMOUNT_MISMATCH',
            );
          }
        }

        final enterpriseId =
            ref.read(activeEnterpriseProvider).value?.id ?? 'default';

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomPart = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
        final sale = Sale(
          id: 'local_sale_${timestamp}_$randomPart',
          enterpriseId: enterpriseId,
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
          amountPaid: amountPaid,
          customerName: _customerNameController.text.isEmpty
              ? null
              : _customerNameController.text.trim(),
          paymentMethod: _paymentMethod,
          cashAmount: _cashAmount,
          mobileMoneyAmount: _mobileMoneyAmount,
          cardAmount: _cardAmount,
        );

        final createdSale = await ref.read(storeControllerProvider).createSale(sale);

        if (mounted) {
          // Garder la vente pour l'impression
          setState(() => _completedSale = createdSale);

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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total à payer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatFCFA(widget.total),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: -0.5,
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
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final settings = ref.read(boutiqueSettingsServiceProvider);
                      final enabledMethods = settings.enabledPaymentMethods;
                      
                      final segments = <ButtonSegment<PaymentMethod>>[];
                      
                      if (enabledMethods.contains('cash')) {
                        segments.add(const ButtonSegment(
                          value: PaymentMethod.cash,
                          label: Text('Espèces'),
                          icon: Icon(Icons.money),
                        ));
                      }
                      
                      if (enabledMethods.contains('mobile_money')) {
                        segments.add(const ButtonSegment(
                          value: PaymentMethod.mobileMoney,
                          label: Text('Mobile Money'),
                          icon: Icon(Icons.phone_android),
                        ));
                      }
                      
                      if (enabledMethods.contains('card')) {
                        segments.add(const ButtonSegment(
                          value: PaymentMethod.card,
                          label: Text('Carte'),
                          icon: Icon(Icons.credit_card),
                        ));
                      }
                      
                      // Enable Mixte if at least 2 methods are enabled
                      if (enabledMethods.length >= 2) {
                        segments.add(const ButtonSegment(
                          value: PaymentMethod.both,
                          label: Text('Mixte'),
                          icon: Icon(Icons.payment),
                        ));
                      }

                      // If current method is distinct from available, reset to first available
                      // This side-effect in build is not ideal but necessary for state consistency if settings changed
                      // Better to do in initState, but let's handle empty case safely
                      if (segments.isEmpty) {
                         return const Center(child: Text("Aucune méthode de paiement activée"));
                      }

                      // Ensure selected is valid
                      if (!segments.any((s) => s.value == _paymentMethod)) {
                         // Must defer state update
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (mounted) _onPaymentMethodChanged(segments.first.value);
                         });
                      }

                      return SegmentedButton<PaymentMethod>(
                        segments: segments,
                        selected: {_paymentMethod},
                        onSelectionChanged: (Set<PaymentMethod> newSelection) {
                          _onPaymentMethodChanged(newSelection.first);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Montant payé - seulement si pas "Les deux"
                  if (_paymentMethod != PaymentMethod.both) ...[
                    TextFormField(
                      controller: _amountPaidController,
                      decoration: const InputDecoration(
                        labelText: 'Montant payé (FCFA) *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onAmountPaidChanged,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        final amount = int.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return 'Montant invalide';
                        }
                        if (amount > widget.total) {
                          return 'Le montant ne peut pas dépasser ${CurrencyFormatter.formatFCFA(widget.total)}';
                        }
                        if (amount < widget.total &&
                            (_paymentMethod == PaymentMethod.cash || _paymentMethod == PaymentMethod.card)) {
                          return 'Le crédit n\'est pas supporté ici';
                        }
                        return null;
                      },
                    ),
                  ],
                  // Répartition si les deux modes sont sélectionnés
                  if (_paymentMethod == PaymentMethod.both) ...[
                    PaymentSplitter(
                      totalAmount: widget.total,
                      onSplitChanged: _onSplitChanged,
                      initialCashAmount: _cashAmount,
                      initialMobileMoneyAmount: _mobileMoneyAmount,
                      initialCardAmount: _cardAmount,
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
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Vente ${_completedSale?.number ?? ""} enregistrée avec succès',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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

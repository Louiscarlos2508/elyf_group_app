import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';
import 'credit_payment/credit_payment_footer.dart';
import 'credit_payment/credit_payment_form_fields.dart';
import 'credit_payment/credit_payment_header.dart';
import 'credit_payment/credit_payment_info_card.dart';
import 'credit_payment/credit_payment_print_helper.dart';
import 'credit_payment/credit_sales_list.dart';

/// Dialog for recording a credit payment.
class CreditPaymentDialog extends ConsumerStatefulWidget {
  const CreditPaymentDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.totalCredit,
    this.preloadedSales,
  });

  final String customerId;
  final String customerName;
  final int totalCredit;
  final List<Sale>? preloadedSales;

  @override
  ConsumerState<CreditPaymentDialog> createState() =>
      _CreditPaymentDialogState();
}

class _CreditPaymentDialogState extends ConsumerState<CreditPaymentDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _omController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  List<Sale> _creditSales = [];
  Sale? _selectedSale;
  PaymentMode _paymentMode = PaymentMode.cash;
  bool _isLoadingSales = true;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour accéder à ref après le montage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCreditSales();
      }
    });

    // Écouter les changements pour mettre à jour les montants si nécessaire
    _cashController.addListener(_onAmountChanged);
    _omController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _cashController.removeListener(_onAmountChanged);
    _omController.removeListener(_onAmountChanged);
    _cashController.dispose();
    _omController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Si on est en mode mixte, on ne fait rien de spécial ici
    // La validation se fera au submit
  }

  void _updatePaymentMode(PaymentMode mode) {
    setState(() {
      _paymentMode = mode;
      // Réinitialiser les champs et pré-remplir si nécessaire
      if (_selectedSale != null) {
        _fillAmountForMode(mode, _selectedSale!);
      }
    });
  }

  void _fillAmountForMode(PaymentMode mode, Sale sale) {
    final amount = sale.remainingAmount.toString();
    switch (mode) {
      case PaymentMode.cash:
        _cashController.text = amount;
        _omController.clear();
        break;
      case PaymentMode.orangeMoney:
        _omController.text = amount;
        _cashController.clear();
        break;
      case PaymentMode.mixed:
        // En mode mixte on ne pré-remplit pas automatiquement pour forcer la saisie consciente
        // ou on pourrait mettre tout en cash par défaut ?
        // Laissons vide pour le moment ou gardons les valeurs précédentes
        break;
    }
  }

  Future<void> _loadCreditSales() async {
    setState(() => _isLoadingSales = true);
    
    // ... (rest of _loadCreditSales is same until setState)
    
    // Si des ventes ont été préchargées, les utiliser directement
    if (widget.preloadedSales != null && widget.preloadedSales!.isNotEmpty) {
      setState(() {
        _creditSales = widget.preloadedSales!.where((s) => s.isCredit).toList();
        if (_creditSales.isNotEmpty && _selectedSale == null) {
          _selectedSale = _creditSales.first;
          _fillAmountForMode(_paymentMode, _selectedSale!);
        }
        _isLoadingSales = false;
      });
      return;
    }

    try {
      final creditRepo = ref.read(creditRepositoryProvider);
      final sales = await creditRepo.fetchCustomerCredits(widget.customerId);
      setState(() {
        _creditSales = sales.where((s) => s.isCredit).toList();
        if (_creditSales.isNotEmpty && _selectedSale == null) {
          _selectedSale = _creditSales.first;
          _fillAmountForMode(_paymentMode, _selectedSale!);
        }
        _isLoadingSales = false;
      });
    } catch (e) {
      // ... (error handling)
    }
  }

  Future<void> _submit() async {
    if (_selectedSale == null) {
      NotificationService.showWarning(
        context,
        'Veuillez sélectionner une vente',
      );
      return;
    }

    final cash = int.tryParse(_cashController.text) ?? 0;
    final om = int.tryParse(_omController.text) ?? 0;
    final amount = cash + om;

    if (amount <= 0) {
       NotificationService.showWarning(context, 'Le montant total doit être supérieur à 0');
       return;
    }

    if (amount > _selectedSale!.remainingAmount) {
      NotificationService.showWarning(
        context,
        'Le montant total ne peut pas dépasser le reste à payer (${CurrencyFormatter.formatCFA(_selectedSale!.remainingAmount)})',
      );
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final creditService = ref.read(creditServiceProvider);
        final payment = CreditPayment(
          id: '',
          saleId: _selectedSale!.id,
          amount: amount,
          date: DateTime.now(),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          cashAmount: cash,
          orangeMoneyAmount: om,
        );

        await creditService.recordPayment(payment);

        if (mounted) {
          // Invalider les providers pour rafraîchir les données
          ref.invalidate(clientsStateProvider);
        }

        // Proposer d'imprimer le reçu
        final remainingAfterPayment = _selectedSale!.remainingAmount - amount;
        if (mounted) {
          await CreditPaymentPrintHelper.showPrintOption(
            context: context,
            customerName: widget.customerName,
            sale: _selectedSale!,
            paymentAmount: amount,
            remainingAfterPayment: remainingAfterPayment,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
          ref.invalidate(clientsStateProvider);
        }

        return 'Paiement de ${CurrencyFormatter.formatCFA(amount)} enregistré';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final theme = Theme.of(context);

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 1000 : 600,
              maxHeight: isWide ? 800 : 750,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // App Bar / Header
                  CreditPaymentHeader(
                    customerName: widget.customerName,
                    onClose: () => Navigator.of(context).pop(),
                  ),

                  Expanded(
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Panel: Info & Selection
                              Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainer,
                                    border: Border(
                                      right: BorderSide(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: CreditPaymentInfoCard(
                                          totalCredit: widget.totalCredit,
                                          creditSalesCount: _creditSales.length,
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: CreditSalesList(
                                          creditSales: _creditSales,
                                          selectedSale: _selectedSale,
                                          onSaleSelected: (sale) {
                                            setState(
                                                () => _selectedSale = sale);
                                            _fillAmountForMode(
                                                _paymentMode, sale);
                                          },
                                          isLoading: _isLoadingSales,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Right Panel: Form
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(32),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              'Détails du Paiement',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            // Payment Mode Selector
                                            SegmentedButton<PaymentMode>(
                                              segments: const [
                                                ButtonSegment<PaymentMode>(
                                                  value: PaymentMode.cash,
                                                  label: Text('Espèces'),
                                                  icon: Icon(Icons.money),
                                                ),
                                                ButtonSegment<PaymentMode>(
                                                  value: PaymentMode.orangeMoney,
                                                  label: Text('Orange Money'),
                                                  icon: Icon(
                                                      Icons.phone_android),
                                                ),
                                                ButtonSegment<PaymentMode>(
                                                  value: PaymentMode.mixed,
                                                  label: Text('Mixte'),
                                                  icon: Icon(Icons.call_split),
                                                ),
                                              ],
                                              selected: {_paymentMode},
                                              onSelectionChanged:
                                                  (Set<PaymentMode> newSelection) {
                                                _updatePaymentMode(
                                                    newSelection.first);
                                              },
                                            ),
                                            const SizedBox(height: 32),

                                            CreditPaymentFormFields(
                                              cashController: _cashController,
                                              omController: _omController,
                                              notesController: _notesController,
                                              selectedSale: _selectedSale,
                                              isLoadingSales: _isLoadingSales,
                                              paymentMode: _paymentMode,
                                              onFillFullAmount: () {
                                                if (_selectedSale != null) {
                                                  _fillAmountForMode(
                                                      _paymentMode,
                                                      _selectedSale!);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: CreditPaymentFooter(
                                        isLoading: _isLoading,
                                        canSubmit: _selectedSale != null &&
                                            !_isLoadingSales,
                                        onCancel: () =>
                                            Navigator.of(context).pop(),
                                        onSubmit: _submit,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mobile layout: Vertical stack
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: CreditPaymentInfoCard(
                                  totalCredit: widget.totalCredit,
                                  creditSalesCount: _creditSales.length,
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: 250, // Fixed height for list
                                        child: CreditSalesList(
                                          creditSales: _creditSales,
                                          selectedSale: _selectedSale,
                                          onSaleSelected: (sale) {
                                            setState(
                                                () => _selectedSale = sale);
                                            _fillAmountForMode(
                                                _paymentMode, sale);
                                          },
                                          isLoading: _isLoadingSales,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // Payment Mode Selector
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SegmentedButton<PaymentMode>(
                                          segments: const [
                                            ButtonSegment<PaymentMode>(
                                              value: PaymentMode.cash,
                                              label: Text('Espèces'),
                                              icon: Icon(Icons.money),
                                            ),
                                            ButtonSegment<PaymentMode>(
                                              value: PaymentMode.orangeMoney,
                                              label: Text('Orange Money'),
                                              icon: Icon(Icons.phone_android),
                                            ),
                                            ButtonSegment<PaymentMode>(
                                              value: PaymentMode.mixed,
                                              label: Text('Mixte'),
                                              icon: Icon(Icons.call_split),
                                            ),
                                          ],
                                          selected: {_paymentMode},
                                          onSelectionChanged:
                                              (Set<PaymentMode> newSelection) {
                                            _updatePaymentMode(
                                                newSelection.first);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      CreditPaymentFormFields(
                                        cashController: _cashController,
                                        omController: _omController,
                                        notesController: _notesController,
                                        selectedSale: _selectedSale,
                                        isLoadingSales: _isLoadingSales,
                                        paymentMode: _paymentMode,
                                        onFillFullAmount: () {
                                          if (_selectedSale != null) {
                                            _fillAmountForMode(
                                                _paymentMode, _selectedSale!);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: CreditPaymentFooter(
                                  isLoading: _isLoading,
                                  canSubmit: _selectedSale != null &&
                                      !_isLoadingSales,
                                  onCancel: () => Navigator.of(context).pop(),
                                  onSubmit: _submit,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



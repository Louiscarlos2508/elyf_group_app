import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';
import 'credit_payment/credit_payment_footer.dart';
import 'credit_payment/credit_payment_form_fields.dart';
import 'credit_payment/credit_payment_header.dart';
import 'credit_payment/credit_payment_info_card.dart';
import 'credit_payment/credit_payment_print_helper.dart';
import 'credit_payment/credit_sales_list.dart';
import 'package:elyf_groupe_app/shared/utils/form_helper_mixin.dart';

/// Dialog for recording a credit payment.
class CreditPaymentDialog extends ConsumerStatefulWidget {
  const CreditPaymentDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.totalCredit,
  });

  final String customerId;
  final String customerName;
  final int totalCredit;

  @override
  ConsumerState<CreditPaymentDialog> createState() =>
      _CreditPaymentDialogState();
}

class _CreditPaymentDialogState extends ConsumerState<CreditPaymentDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  List<Sale> _creditSales = [];
  Sale? _selectedSale;
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCreditSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final creditRepo = ref.read(creditRepositoryProvider);
      final sales = await creditRepo.fetchCustomerCredits(widget.customerId);
      setState(() {
        _creditSales = sales.where((s) => s.isCredit).toList();
        if (_creditSales.isNotEmpty && _selectedSale == null) {
          _selectedSale = _creditSales.first;
        }
        _isLoadingSales = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSales = false);
      NotificationService.showError(context, 'Erreur lors du chargement: ${e.toString()}');
    }
  }


  Future<void> _submit() async {
    if (_selectedSale == null) {
      NotificationService.showWarning(context, 'Veuillez sélectionner une vente');
      return;
    }

    final amount = int.parse(_amountController.text);
    if (amount > _selectedSale!.remainingAmount) {
      NotificationService.showWarning(
        context,
        'Le montant ne peut pas dépasser le reste à payer (${CurrencyFormatter.formatCFA(_selectedSale!.remainingAmount)})',
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
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CreditPaymentHeader(
                customerName: widget.customerName,
                onClose: () => Navigator.of(context).pop(),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreditPaymentInfoCard(
                        totalCredit: widget.totalCredit,
                        creditSalesCount: _creditSales.length,
                      ),
                      const SizedBox(height: 24),
                      CreditSalesList(
                        creditSales: _creditSales,
                        selectedSale: _selectedSale,
                        onSaleSelected: (sale) => setState(() => _selectedSale = sale),
                        isLoading: _isLoadingSales,
                      ),
                      const SizedBox(height: 24),
                      CreditPaymentFormFields(
                        amountController: _amountController,
                        notesController: _notesController,
                        selectedSale: _selectedSale,
                        isLoadingSales: _isLoadingSales,
                        onFillFullAmount: () {
                          if (_selectedSale != null) {
                            _amountController.text = _selectedSale!.remainingAmount.toString();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              CreditPaymentFooter(
                isLoading: _isLoading,
                canSubmit: _selectedSale != null && !_isLoadingSales,
                onCancel: () => Navigator.of(context).pop(),
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


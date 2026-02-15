import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/domain/entities/payment_method.dart';
import '../../../../core/pdf/unified_payment_pdf_service.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import 'payment_form_fields.dart';

class PaymentFormDialog extends ConsumerStatefulWidget {
  const PaymentFormDialog({super.key, this.payment, this.initialContract});

  final Payment? payment;
  final Contract? initialContract;

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  Contract? _selectedContract;
  DateTime _paymentDate = DateTime.now();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  PaymentStatus _status = PaymentStatus.paid;
  PaymentType _paymentType = PaymentType.rent;
  int? _month;
  int? _year;
  final _notesController = TextEditingController();
  final _transactionIdController = TextEditingController(); 
  final _cashAmountController = TextEditingController(); 
  final _mobileMoneyAmountController = TextEditingController(); 
  bool _isSaving = false;
  bool _printReceipt = true;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      final p = widget.payment!;
      _selectedContract = p.contract;
      _paymentDate = p.paymentDate;
      _amountController.text = p.amount.toString();
      _paidAmountController.text = p.paidAmount.toString();
      _paymentMethod = p.paymentMethod;
      _status = p.status;
      _paymentType = p.paymentType ?? PaymentType.rent;
      _month = p.month;
      _year = p.year;
      _notesController.text = p.notes ?? '';
      if (p.paymentMethod == PaymentMethod.both) {
        _cashAmountController.text = p.cashAmount?.toString() ?? '';
        _mobileMoneyAmountController.text = p.mobileMoneyAmount?.toString() ?? '';
      }
    } else {
      _month = DateTime.now().month;
      _year = DateTime.now().year;
      
      if (widget.initialContract != null) {
        _selectedContract = widget.initialContract;
        _amountController.text = widget.initialContract!.monthlyRent.toString();
        _paidAmountController.text = widget.initialContract!.monthlyRent.toString();
        
        // Suggest next unpaid month for this contract
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final payments = await ref.read(paymentControllerProvider).getPaymentsByContract(widget.initialContract!.id);
          final validPayments = payments.where((p) => p.status != PaymentStatus.cancelled).toList();
          
          if (validPayments.isNotEmpty) {
            // Sort to find the latest month/year paid
            validPayments.sort((a, b) {
              final valA = (a.year ?? 0) * 12 + (a.month ?? 0);
              final valB = (b.year ?? 0) * 12 + (b.month ?? 0);
              return valB.compareTo(valA);
            });
            
            final latest = validPayments.first;
            int nextMonth = (latest.month ?? DateTime.now().month) + 1;
            int nextYear = (latest.year ?? DateTime.now().year);
            
            if (nextMonth > 12) {
              nextMonth = 1;
              nextYear++;
            }
            
            if (mounted) {
              setState(() {
                _month = nextMonth;
                _year = nextYear;
              });
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _transactionIdController.dispose();
    _cashAmountController.dispose();
    _mobileMoneyAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
        if (_month == null || _year == null) {
          _month = picked.month;
          _year = picked.year;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedContract == null) {
      NotificationService.showWarning(
        context,
        'Veuillez sélectionner un contrat',
      );
      return;
    }

    if (_paymentMethod == PaymentMethod.both) {
      final total = int.tryParse(_amountController.text) ?? 0;
      final cash = int.tryParse(_cashAmountController.text) ?? 0;
      final mobile = int.tryParse(_mobileMoneyAmountController.text) ?? 0;

      if (cash + mobile != total) {
        NotificationService.showError(
          context,
          'La somme (Espèces + Mobile) doit être égale au montant total ($total)',
        );
        return;
      }
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isSaving = isLoading),
      onSubmit: () async {
        final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? 'default';
        final totalAmount = int.parse(_amountController.text);
        final paidAmount = int.parse(_paidAmountController.text);
        
        // Calculate status automatically if not manually overridden or just force logic
        var status = _status;
        if (paidAmount == 0) {
          status = PaymentStatus.pending;
        } else if (paidAmount < totalAmount) {
          status = PaymentStatus.partial;
        } else if (paidAmount >= totalAmount) {
          status = PaymentStatus.paid;
        }

        final payment = Payment(
          id: widget.payment?.id ?? IdGenerator.generate(),
          enterpriseId: enterpriseId,
          contractId: _selectedContract!.id,
          amount: totalAmount,
          paidAmount: paidAmount,
          paymentDate: _paymentDate,
          paymentMethod: _paymentMethod,
          status: status,
          cashAmount: _paymentMethod == PaymentMethod.both ? int.tryParse(_cashAmountController.text) : null,
          mobileMoneyAmount: _paymentMethod == PaymentMethod.both ? int.tryParse(_mobileMoneyAmountController.text) : null,
          contract: _selectedContract,
          month: _month,
          year: _year,
          receiptNumber: null, // Champ supprimé du formulaire, laissé à null ou géré par le backend/PDF
          notes: _notesController.text.trim().isEmpty
              ? null
              : (_transactionIdController.text.isNotEmpty 
                  ? 'ID Trans: ${_transactionIdController.text.trim()}\n${_notesController.text.trim()}'
                  : _notesController.text.trim()),
          paymentType: _paymentType,
          createdAt: widget.payment?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ref.read(paymentControllerProvider);
        Payment savedPayment;
        if (widget.payment == null) {
          savedPayment = await controller.createPayment(payment);
        } else {
          savedPayment = await controller.updatePayment(payment);
        }

        if (_printReceipt && mounted) {
          try {
             await controller.printReceipt(savedPayment.id);
          } catch (e) {
            // On ne bloque pas le flux si l'impression échoue, mais on notifie
            if (mounted) {
               NotificationService.showWarning(context, 'Erreur lors de l\'impression du ticket: $e');
            }
          }
        }

        if (mounted) {
          ref.invalidate(paymentsWithRelationsProvider);
          Navigator.of(context).pop(savedPayment);

          // Proposer de générer la facture uniquement pour les nouveaux paiements
          if (widget.payment == null) {
            _showInvoiceDialog(savedPayment);
          }
        }

        return widget.payment == null
            ? 'Paiement enregistré avec succès'
            : 'Paiement mis à jour avec succès';
      },
    );
  }

  Future<void> _showInvoiceDialog(Payment payment) async {
    if (!mounted) return;

    final isDeposit = payment.paymentType == PaymentType.deposit;
    final title = isDeposit ? 'Facture de caution' : 'Facture de loyer';
    final content = isDeposit
        ? 'Voulez-vous générer la facture PDF pour ce paiement de caution ?'
        : 'Voulez-vous générer la facture PDF pour ce paiement de loyer ?';

    final shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );

    if (shouldGenerate == true && mounted) {
      await _generateInvoice(payment);
    } else if (mounted) {
      NotificationService.showSuccess(
        context,
        widget.payment == null
            ? 'Paiement enregistré avec succès'
            : 'Paiement mis à jour avec succès',
      );
    }
  }

  Future<void> _generateInvoice(Payment payment) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfService = UnifiedPaymentPdfService.instance;
      final file = await pdfService.generateDocument(
        payment: payment,
        asInvoice: true,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
      }

      if (mounted) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          NotificationService.showInfo(
            context,
            'Facture générée: ${file.path}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
        NotificationService.showError(
          context,
          'Erreur lors de la génération de la facture: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractsWithRelationsProvider);

    return FormDialog(
      title: widget.payment == null
          ? 'Nouveau paiement'
          : 'Modifier le paiement',
      saveLabel: widget.payment == null ? 'Enregistrer' : 'Enregistrer',
      onSave: _isSaving ? null : _save,
      isLoading: _isSaving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            contractsAsync.when(
              data: (contracts) => PaymentFormFields.contractField(
                selectedContract: _selectedContract,
                contracts: contracts,
                // Disable selection if initialContract is provided (and we are creating new)
                enabled: widget.initialContract == null || widget.payment != null,
                onChanged: (value) {
                  setState(() {
                    _selectedContract = value;
                    if (value != null && widget.payment == null) {
                      // Préremplir selon le type de paiement
                      if (_paymentType == PaymentType.rent) {
                        _amountController.text = value.monthlyRent.toString();
                      } else if (_paymentType == PaymentType.deposit) {
                        _amountController.text = value.calculatedDeposit
                            .toString();
                      }
                    }
                  });
                },
                validator: (value) {
                  if (value == null) return 'Le contrat est requis';
                  return null;
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
            ),
            const SizedBox(height: 16),
            PaymentFormFields.paymentTypeField(
              value: _paymentType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paymentType = value;
                    // Mettre à jour le montant selon le type
                    if (_selectedContract != null) {
                      if (value == PaymentType.rent) {
                        _amountController.text = _selectedContract!.monthlyRent
                            .toString();
                      } else if (value == PaymentType.deposit) {
                        _amountController.text = _selectedContract!
                            .calculatedDeposit
                            .toString();
                      }
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            PaymentFormFields.dateField(
              paymentDate: _paymentDate,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            PaymentFormFields.amountField(
              controller: _amountController,
              validator: (value) => Validators.amount(value),
              label: 'Montant du loyer (FCFA) *',
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: _amountController,
              builder: (context, value, child) {
                final total = int.tryParse(value.text) ?? 0;
                return PaymentFormFields.paidAmountField(
                  controller: _paidAmountController,
                  validator: (val) {
                    final res = Validators.amount(val);
                    if (res != null) return res;
                    final paid = int.tryParse(val!) ?? 0;
                    if (paid > total) return 'Le montant reçu ne peut pas dépasser le loyer';
                    return null;
                  },
                  helperText: (int.tryParse(_paidAmountController.text) ?? 0) < total
                      ? 'Reste à payer : ${total - (int.tryParse(_paidAmountController.text) ?? 0)} FCFA'
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            PaymentFormFields.monthYearFields(
              month: _month,
              year: _year,
              onMonthChanged: (value) => setState(() => _month = value),
              onYearChanged: (value) => setState(() => _year = value),
            ),
            const SizedBox(height: 16),
            PaymentFormFields.paymentMethodField(
              value: _paymentMethod,
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
            ),
            if (_paymentMethod == PaymentMethod.mobileMoney) ...[
              const SizedBox(height: 16),
              PaymentFormFields.transactionIdField(
                controller: _transactionIdController,
              ),
            ],
            if (_paymentMethod == PaymentMethod.both) ...[
              const SizedBox(height: 16),
              PaymentFormFields.splitAmountFields(
                cashController: _cashAmountController,
                mobileMoneyController: _mobileMoneyAmountController,
                cashValidator: (v) => Validators.required(v),
                mobileMoneyValidator: (v) => Validators.required(v),
              ),
            ],
            const SizedBox(height: 16),
            PaymentFormFields.statusField(
              value: _status,
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            PaymentFormFields.notesField(controller: _notesController),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Imprimer le reçu'),
              subtitle: const Text('Imprimer un ticket sur l\'imprimante thermique'),
              value: _printReceipt,
              onChanged: (value) => setState(() => _printReceipt = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

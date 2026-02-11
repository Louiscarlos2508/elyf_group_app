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
  const PaymentFormDialog({super.key, this.payment});

  final Payment? payment;

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  Contract? _selectedContract;
  DateTime _paymentDate = DateTime.now();
  final _amountController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      final p = widget.payment!;
      _selectedContract = p.contract;
      _paymentDate = p.paymentDate;
      _amountController.text = p.amount.toString();
      _paymentMethod = p.paymentMethod;
      _status = p.status;
      _paymentType = p.paymentType ?? PaymentType.rent;
      _month = p.month;
      _year = p.year;
      _year = p.year;
      _year = p.year;
      _notesController.text = p.notes ?? '';
      // Initialiser les champs split si nécessaire
      if (p.paymentMethod == PaymentMethod.both) {
        _cashAmountController.text = p.cashAmount?.toString() ?? '';
        _mobileMoneyAmountController.text = p.mobileMoneyAmount?.toString() ?? '';
      }
      // Note: Transaction ID n'est pas encore dans l'entité Payment, on l'ajoute dans les notes pour l'instant ou on l'ignore si non supporté par l'entité
      // Si l'utilisateur veut vraiment le stocker proprement, il faudrait l'ajouter à l'entité. 
      // Pour l'instant on va supposer qu'il est concaténé dans les notes ou on l'ajoute.
      // Le prompt user ne demandait pas explicitement de le stocker dans un nouveau champ, mais le plan disait "Add _transactionIdController".
      // L'entité Payment n'a PAS de champ transactionId. Je vais l'ajouter aux notes lors de la sauvegarde.
    } else {
      _month = DateTime.now().month;
      _year = DateTime.now().year;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
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
        final payment = Payment(
          id: widget.payment?.id ?? IdGenerator.generate(),
          enterpriseId: enterpriseId,
          contractId: _selectedContract!.id,
          amount: int.parse(_amountController.text),
          paymentDate: _paymentDate,
          paymentMethod: _paymentMethod,
          status: _status,
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
        if (widget.payment == null) {
          await controller.createPayment(payment);
        } else {
          await controller.updatePayment(payment);
        }

        if (mounted) {
          ref.invalidate(paymentsWithRelationsProvider);
          Navigator.of(context).pop(payment);

          // Proposer de générer la facture uniquement pour les nouveaux paiements
          if (widget.payment == null) {
            _showInvoiceDialog(payment);
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

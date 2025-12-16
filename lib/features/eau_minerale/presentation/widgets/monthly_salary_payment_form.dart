import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/date_formatter.dart';
import '../../application/providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/exceptions/duplicate_payment_exception.dart';
import '../../domain/exceptions/invalid_payment_date_exception.dart';
import '../../domain/exceptions/invalid_payment_amount_exception.dart';
import 'monthly_salary_payment_date_section.dart';
import 'monthly_salary_payment_header.dart';
import 'payment_amount_display.dart';
import 'payment_notes_field.dart';
import 'payment_signature_dialog.dart';

/// Form for creating a monthly salary payment for a fixed employee.
class MonthlySalaryPaymentForm extends ConsumerStatefulWidget {
  const MonthlySalaryPaymentForm({
    super.key,
    required this.employee,
    required this.existingPayments,
    this.onSubmit,
  });

  final Employee employee;
  final List<SalaryPayment> existingPayments;
  final Future<void> Function()? onSubmit;

  @override
  ConsumerState<MonthlySalaryPaymentForm> createState() =>
      MonthlySalaryPaymentFormState();
}

class MonthlySalaryPaymentFormState
    extends ConsumerState<MonthlySalaryPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _period = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePeriod();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializePeriod() {
    final now = DateTime.now();
    setState(() {
      _period = DateFormatter.formatPeriod(now);
    });
  }

  void _handleDateSelected(DateTime date) {
    setState(() {
      _paymentDate = date;
      _period = DateFormatter.formatPeriod(date);
    });
  }

  /// Validates the payment before submission.
  void _validatePayment() {
    // Validate date is not in the future
    final now = DateTime.now();
    if (_paymentDate.isAfter(now)) {
      throw InvalidPaymentDateException(
        reason: 'La date de paiement ne peut pas être dans le futur',
      );
    }

    // Validate amount matches employee's monthly salary
    if (widget.employee.monthlySalary <= 0) {
      throw InvalidPaymentAmountException(
        expectedAmount: widget.employee.monthlySalary,
        actualAmount: widget.employee.monthlySalary,
      );
    }

    // Check for duplicate payment for the same month/year
    final hasDuplicate = widget.existingPayments.any((p) =>
        p.date.month == _paymentDate.month &&
        p.date.year == _paymentDate.year);

    if (hasDuplicate) {
      throw DuplicatePaymentException(
        employeeName: widget.employee.name,
        period: _period,
      );
    }
  }

  Future<void> _requestSignatureAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _validatePayment();
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is DuplicatePaymentException) {
        message = e.toString();
      } else if (e is InvalidPaymentDateException) {
        message = e.toString();
      } else if (e is InvalidPaymentAmountException) {
        message = e.toString();
      } else {
        message = 'Erreur de validation: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Demander la signature avant d'enregistrer le paiement
    final signature = await showDialog<Uint8List>(
      context: context,
      builder: (dialogContext) => PaymentSignatureDialog(
        workerName: widget.employee.name,
        amount: widget.employee.monthlySalary,
        period: _period,
        onPaid: (sig) {
          Navigator.of(context).pop(sig);
        },
      ),
    );

    if (signature == null) {
      // L'utilisateur a annulé la signature
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payment = SalaryPayment(
        id: 'salary-${DateTime.now().millisecondsSinceEpoch}',
        employeeId: widget.employee.id,
        employeeName: widget.employee.name,
        amount: widget.employee.monthlySalary,
        date: _paymentDate,
        period: _period,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        signature: signature,
      );

      await ref.read(salaryControllerProvider).createMonthlySalaryPayment(payment);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(salaryStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement de salaire enregistré avec signature'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is DuplicatePaymentException) {
        message = e.toString();
      } else if (e is InvalidPaymentDateException) {
        message = e.toString();
      } else if (e is InvalidPaymentAmountException) {
        message = e.toString();
      } else {
        message = 'Erreur: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Public method to submit the form (called by FormDialog).
  Future<void> submit() async {
    await _requestSignatureAndSubmit();
  }


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthlySalaryPaymentHeader(employee: widget.employee),
          const SizedBox(height: 16),
          PaymentAmountDisplay(amount: widget.employee.monthlySalary),
          const SizedBox(height: 16),
          MonthlySalaryPaymentDateSection(
            paymentDate: _paymentDate,
            period: _period,
            onDateSelected: _handleDateSelected,
          ),
          const SizedBox(height: 16),
          PaymentNotesField(controller: _notesController),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}


import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/salary_payment.dart';
import 'monthly_salary_payment_date_section.dart';
import 'monthly_salary_payment_header.dart';
import 'payment_signature_dialog.dart';
import 'payment_signature_dialog.dart';

/// Form for creating a monthly salary payment for a fixed employee.
class MonthlySalaryPaymentForm extends ConsumerStatefulWidget {
  const MonthlySalaryPaymentForm({
    super.key,
    required this.employee,
  });

  final Employee employee;

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
    final monthName = _getMonthName(now.month);
    setState(() {
      _period = '$monthName ${now.year}';
    });
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return months[month - 1];
  }

  void _handleDateSelected(DateTime date) {
    setState(() {
      _paymentDate = date;
      final monthName = _getMonthName(date.month);
      _period = '$monthName ${date.year}';
    });
  }

  Future<void> _requestSignatureAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

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
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> submit() async {
    await _requestSignatureAndSubmit();
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
            MonthlySalaryPaymentHeader(employee: widget.employee),
            const SizedBox(height: 16),
            MonthlySalaryPaymentDateSection(
              paymentDate: _paymentDate,
              period: _period,
              onDateSelected: _handleDateSelected,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.note),
                hintText: 'Ex: Paiement complet, Acompte, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}


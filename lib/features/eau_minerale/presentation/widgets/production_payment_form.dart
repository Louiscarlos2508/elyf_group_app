import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/production_payment_person.dart';
import 'production_payment_date_selector.dart';
import 'production_payment_period_selector.dart';
import 'production_payment_persons_section.dart';
import 'production_payment_total_summary.dart';
import 'production_period_formatter.dart';

/// Form for creating production payments.
class ProductionPaymentForm extends ConsumerStatefulWidget {
  const ProductionPaymentForm({super.key});

  @override
  ConsumerState<ProductionPaymentForm> createState() =>
      ProductionPaymentFormState();
}

class ProductionPaymentFormState
    extends ConsumerState<ProductionPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _period = '';
  final List<ProductionPaymentPerson> _persons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePeriod();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializePeriod() async {
    final config = await ref.read(productionPeriodConfigProvider.future);
    final now = DateTime.now();
    final period = config.getPeriodForDate(now);
    final formatter = ProductionPeriodFormatter(config);
    if (mounted) {
      setState(() {
        _period = formatter.formatPeriod(period, now);
      });
    }
  }

  void _handleDateSelected(DateTime date) {
    setState(() => _paymentDate = date);
  }

  void _addPerson() {
    setState(() {
      _persons.add(const ProductionPaymentPerson(
        name: '',
        pricePerDay: 0,
        daysWorked: 0,
      ));
    });
  }

  void _removePerson(int index) {
    setState(() => _persons.removeAt(index));
  }

  void _updatePerson(int index, ProductionPaymentPerson person) {
    setState(() => _persons[index] = person);
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final validationService = ref.read(productionPaymentValidationServiceProvider);
    final validationError = validationService.getPersonsValidationError(_persons);
    if (validationError != null) {
      NotificationService.showWarning(context, validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payment = ProductionPayment(
        id: 'payment-${DateTime.now().millisecondsSinceEpoch}',
        period: _period,
        paymentDate: _paymentDate,
        persons: _persons,
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(salaryControllerProvider).createProductionPayment(payment);

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(salaryStateProvider);
      NotificationService.showSuccess(context, 'Paiements enregistrés');
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductionPaymentPeriodSelector(
              period: _period,
              onPeriodChanged: (period) => setState(() => _period = period),
            ),
            const SizedBox(height: 16),
            ProductionPaymentDateSelector(
              selectedDate: _paymentDate,
              onDateSelected: _handleDateSelected,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Note / Description (optionnel)',
                prefixIcon: Icon(Icons.note),
                hintText: 'Ex: Production de 500 packs, 3 jours de travail...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ProductionPaymentPersonsSection(
              persons: _persons,
              onAddPerson: _addPerson,
              onRemovePerson: _removePerson,
              onUpdatePerson: _updatePerson,
              period: _period,
              onLoadFromProduction: (persons) {
                setState(() {
                  _persons.clear();
                  _persons.addAll(persons);
                });
              },
            ),
            if (_persons.isNotEmpty) ...[
              const SizedBox(height: 24),
              ProductionPaymentTotalSummary(persons: _persons),
            ],
          ],
        ),
      ),
    );
  }
}


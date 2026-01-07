import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';
import '../../domain/services/collection_calculation_service.dart';
import 'payment_form/leak_report_section.dart';
import 'payment_form/payment_amount_input.dart';
import 'payment_form/payment_submit_handler.dart';

/// Dialog pour enregistrer un paiement pour une collecte.
class PaymentFormDialog extends ConsumerStatefulWidget {
  const PaymentFormDialog({
    super.key,
    required this.tour,
    required this.collection,
  });

  final Tour tour;
  final Collection collection;

  @override
  ConsumerState<PaymentFormDialog> createState() =>
      _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final Map<int, TextEditingController> _leakControllers = {};
  double _amount = 0.0;
  Map<int, int> _leaks = {};

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);

    // Initialiser les contrôleurs de fuites pour chaque poids
    for (final weight in widget.collection.emptyBottles.keys) {
      final leakQty = widget.collection.leaks[weight] ?? 0;
      _leaks[weight] = leakQty;
      _leakControllers[weight] = TextEditingController(
        text: leakQty.toString(),
      );
      _leakControllers[weight]!.addListener(() => _onLeakChanged(weight));
    }

    // Pré-remplir avec le montant restant
    _amount = widget.collection.remainingAmount;
    _amountController.text = _amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    for (final controller in _leakControllers.values) {
      controller.removeListener(() {});
      controller.dispose();
    }
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text.replaceAll(' ', '');
    final value = double.tryParse(text) ?? 0.0;
    setState(() {
      _amount = value;
    });
  }

  void _onLeakChanged(int weight) {
    final controller = _leakControllers[weight]!;
    final text = controller.text.replaceAll(' ', '');
    final value = int.tryParse(text) ?? 0;
    final maxLeaks = widget.collection.emptyBottles[weight] ?? 0;

    if (value > maxLeaks) {
      controller.text = maxLeaks.toString();
      _leaks[weight] = maxLeaks;
    } else if (value < 0) {
      controller.text = '0';
      _leaks[weight] = 0;
    } else {
      _leaks[weight] = value;
    }

    setState(() {
      // Recalculer le montant à payer après changement de fuites
      _amount = CollectionCalculationService.calculateAmountDue(
        widget.collection,
        _leaks,
      );
      _amountController.text = _amount.toStringAsFixed(0);
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    await PaymentSubmitHandler.submit(
      context: context,
      ref: ref,
      tour: widget.tour,
      collection: widget.collection,
      amount: _amount,
      leaks: _leaks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final newAmountDue = CollectionCalculationService.calculateAmountDue(
      widget.collection,
      _leaks,
    );
    final amountToPayNow = newAmountDue;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormDialogHeader(
                  title: 'Enregistrer un paiement',
                  subtitle: widget.collection.clientName,
                  icon: Icons.payment,
                ),
                const SizedBox(height: 24),
                PaymentAmountInput(
                  collection: widget.collection,
                  newAmountDue: newAmountDue,
                  amountController: _amountController,
                  amountToPayNow: amountToPayNow,
                ),
                const SizedBox(height: 11.99),
                LeakReportSection(
                  collection: widget.collection,
                  leakControllers: _leakControllers,
                ),
                const SizedBox(height: 11.99),
                Container(
                  height: 0.999,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 11.99),
                FormDialogActions(
                  onCancel: () => Navigator.of(context).pop(false),
                  onSubmit: _submitPayment,
                  submitLabel: 'Valider',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

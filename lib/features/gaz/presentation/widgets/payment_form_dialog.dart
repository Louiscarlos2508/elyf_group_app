import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../application/providers.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/tour.dart';
import 'payment_form/leak_report_section.dart';
import 'payment_form/payment_amount_input.dart';

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
      _amount = _calculateNewAmountDue();
      _amountController.text = _amount.toStringAsFixed(0);
    });
  }

  /// Calcule le nouveau montant dû après déduction des fuites.
  double _calculateNewAmountDue() {
    double total = 0.0;
    for (final entry in widget.collection.emptyBottles.entries) {
      final weight = entry.key;
      final qty = entry.value;
      final leakQty = _leaks[weight] ?? 0;
      final validBottles = qty - leakQty;
      final price = widget.collection.getUnitPriceForWeight(weight);
      total += validBottles * price;
    }
    // Soustraire ce qui a déjà été payé
    return (total - widget.collection.amountPaid).clamp(0.0, double.infinity);
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le montant doit être supérieur à 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newAmountDue = _calculateNewAmountDue();
    if (_amount > newAmountDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le montant ne peut pas dépasser ${newAmountDue.toStringAsFixed(0)} FCFA',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      
      // Mettre à jour la collecte avec les fuites et le nouveau paiement
      final updatedCollection = widget.collection.copyWith(
        leaks: _leaks,
        amountPaid: widget.collection.amountPaid + _amount,
        paymentDate: DateTime.now(),
      );

      // Mettre à jour le tour avec la collecte modifiée
      final updatedCollections = widget.tour.collections.map((c) {
        return c.id == updatedCollection.id ? updatedCollection : c;
      }).toList();

      await controller.updateTour(
        widget.tour.copyWith(collections: updatedCollections),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newAmountDue = _calculateNewAmountDue();
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
                // Titre
                Row(
                  children: [
                    const Icon(
                      Icons.payment,
                      size: 24,
                      color: Color(0xFF0A0A0A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enregistrer un paiement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.collection.clientName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF4A5565),
                  ),
                ),
                const SizedBox(height: 24),
                // Section des montants et saisie
                PaymentAmountInput(
                  collection: widget.collection,
                  newAmountDue: newAmountDue,
                  amountController: _amountController,
                  amountToPayNow: amountToPayNow,
                ),
                const SizedBox(height: 11.99),
                // Section des fuites
                LeakReportSection(
                  collection: widget.collection,
                  leakControllers: _leakControllers,
                ),
                const SizedBox(height: 11.99),
                // Divider
                Container(
                  height: 0.999,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 11.99),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: GazButtonStyles.outlined,
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7.993),
                    Expanded(
                      child: FilledButton(
                        style: GazButtonStyles.filledPrimary,
                        onPressed: _submitPayment,
                        child: const Text(
                          'Valider',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

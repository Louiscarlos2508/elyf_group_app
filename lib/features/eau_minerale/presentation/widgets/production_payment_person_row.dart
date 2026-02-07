import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_payment_person.dart';

/// Row widget for editing a production payment person.
class ProductionPaymentPersonRow extends ConsumerStatefulWidget {
  const ProductionPaymentPersonRow({
    super.key,
    required this.person,
    required this.onChanged,
    required this.onRemove,
  });

  final ProductionPaymentPerson person;
  final ValueChanged<ProductionPaymentPerson> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<ProductionPaymentPersonRow> createState() =>
      _ProductionPaymentPersonRowState();
}

class _ProductionPaymentPersonRowState
    extends ConsumerState<ProductionPaymentPersonRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _pricePerDayController;
  late final TextEditingController _daysController;
  late final TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _pricePerDayController = TextEditingController(
      text: widget.person.pricePerDay.toString(),
    );
    _daysController = TextEditingController(
      text: widget.person.daysWorked.toString(),
    );
    _totalController = TextEditingController(
      text: widget.person.effectiveTotalAmount > 0
          ? widget.person.effectiveTotalAmount.toString()
          : '',
    );

    _nameController.addListener(_updatePerson);
    _pricePerDayController.addListener(_updatePerson);
    _daysController.addListener(_updatePerson);
    _totalController.addListener(_updateTotal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pricePerDayController.dispose();
    _daysController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _updatePerson() {
    final name = _nameController.text.trim();
    final pricePerDay = int.tryParse(_pricePerDayController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;

    // Utiliser le service de calcul pour extraire la logique métier
    final calculationService = ref.read(
      productionPaymentCalculationServiceProvider,
    );
    final updatedPerson = calculationService.updatePersonCalculations(
      person: widget.person,
      newPricePerDay: pricePerDay,
      newDaysWorked: days,
    );

    // Mettre à jour le champ total si calculé automatiquement
    if (updatedPerson.effectiveTotalAmount > 0 &&
        _totalController.text !=
            updatedPerson.effectiveTotalAmount.toString()) {
      _totalController.text = updatedPerson.effectiveTotalAmount.toString();
    }

    widget.onChanged(updatedPerson.copyWith(name: name));
  }

  void _updateTotal() {
    final total = int.tryParse(_totalController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;

    if (total > 0 && days > 0) {
      // Utiliser le service de calcul pour extraire la logique métier
      final calculationService = ref.read(
        productionPaymentCalculationServiceProvider,
      );
      final calculatedPricePerDay = calculationService.calculatePricePerDay(
        totalAmount: total,
        daysWorked: days,
      );

      if (_pricePerDayController.text != calculatedPricePerDay.toString()) {
        _pricePerDayController.text = calculatedPricePerDay.toString();
      }

      // Mettre à jour la personne avec le nouveau calcul
      final updatedPerson = calculationService.updatePersonCalculations(
        person: widget.person,
        newTotalAmount: total,
        newDaysWorked: days,
      );
      widget.onChanged(updatedPerson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Name + Delete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nom du bénéficiaire',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: theme.colorScheme.error, size: 20),
                onPressed: widget.onRemove,
                tooltip: 'Retirer',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Data Row: Price x Days = Total
          Row(
            children: [
              // Price
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _pricePerDayController,
                  decoration: _buildInputDecoration(
                    label: 'Prix/j',
                    hintText: '5000',
                  ),
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              
              // Multiplier Symbol
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '×',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.outline,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              
              // Days
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _daysController,
                  decoration: _buildInputDecoration(
                    label: 'Jours',
                    hintText: '5',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              
              // Equals Symbol
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '=',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.outline,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              
              // Total
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _totalController,
                  decoration: _buildInputDecoration(
                    label: 'Total',
                    hintText: '25000',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, String? hintText, IconData? icon}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: colors.primary) : null,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: colors.surfaceContainerLowest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

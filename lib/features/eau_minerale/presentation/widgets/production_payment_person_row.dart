import 'package:flutter/material.dart';

import '../../domain/entities/production_payment_person.dart';

/// Row widget for editing a production payment person.
class ProductionPaymentPersonRow extends StatefulWidget {
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
  State<ProductionPaymentPersonRow> createState() =>
      _ProductionPaymentPersonRowState();
}

class _ProductionPaymentPersonRowState
    extends State<ProductionPaymentPersonRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _pricePerDayController;
  late final TextEditingController _daysController;
  late final TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _pricePerDayController =
        TextEditingController(text: widget.person.pricePerDay.toString());
    _daysController =
        TextEditingController(text: widget.person.daysWorked.toString());
    _totalController = TextEditingController(
      text: widget.person.totalAmount > 0
          ? widget.person.totalAmount.toString()
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

    final total = pricePerDay * days;
    if (total > 0 && _totalController.text != total.toString()) {
      _totalController.text = total.toString();
    }

    widget.onChanged(ProductionPaymentPerson(
      name: name,
      pricePerDay: pricePerDay,
      daysWorked: days,
    ));
  }

  void _updateTotal() {
    final total = int.tryParse(_totalController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;

    if (total > 0 && days > 0) {
      final pricePerDay = (total / days).round();
      if (_pricePerDayController.text != pricePerDay.toString()) {
        _pricePerDayController.text = pricePerDay.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    isDense: true,
                    hintText: 'Ex: Mamadou Traoré',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pricePerDayController,
                  decoration: const InputDecoration(
                    labelText: 'Prix/jour (FCFA)',
                    isDense: true,
                    hintText: 'Ex: 5000',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _daysController,
                  decoration: const InputDecoration(
                    labelText: 'Nb jours',
                    isDense: true,
                    hintText: 'Ex: 5',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _totalController,
                  decoration: const InputDecoration(
                    labelText: 'Montant Total (FCFA)*',
                    isDense: true,
                    helperText: 'Auto-calculé ou saisir manuellement',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


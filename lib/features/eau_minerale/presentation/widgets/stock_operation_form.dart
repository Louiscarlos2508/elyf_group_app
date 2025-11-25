import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/stock_item.dart';
import 'stock_item_selector.dart';
import 'stock_operation_date_selector.dart';
import 'stock_operation_type_selector.dart';

/// Form for creating stock operations (entry/exit).
class StockOperationForm extends ConsumerStatefulWidget {
  const StockOperationForm({super.key});

  @override
  ConsumerState<StockOperationForm> createState() =>
      StockOperationFormState();
}

class StockOperationFormState extends ConsumerState<StockOperationForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  StockItem? _selectedItem;
  StockMovementType _movementType = StockMovementType.entry;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // TODO: Implement stock movement creation in repository
      // For now, just show success message
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(stockStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _movementType == StockMovementType.entry
                ? 'Entrée de stock enregistrée'
                : 'Sortie de stock enregistrée',
          ),
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
            StockOperationTypeSelector(
              movementType: _movementType,
              onChanged: (type) => setState(() => _movementType = type),
            ),
            const SizedBox(height: 16),
            StockItemSelector(
              selectedItem: _selectedItem,
              onItemSelected: (item) => setState(() => _selectedItem = item),
            ),
            if (_selectedItem == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text(
                  'Requis',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            StockOperationDateSelector(
              date: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 16),
            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité',
                prefixIcon: const Icon(Icons.numbers),
                suffixText: _selectedItem?.unit ?? '',
                helperText: _selectedItem != null
                    ? 'Stock actuel: ${_selectedItem!.quantity} ${_selectedItem!.unit}'
                    : null,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final qty = double.tryParse(v);
                if (qty == null || qty <= 0) return 'Quantité invalide';
                if (_movementType == StockMovementType.exit &&
                    _selectedItem != null &&
                    qty > _selectedItem!.quantity) {
                  return 'Quantité supérieure au stock disponible';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                prefixIcon: Icon(Icons.note),
                helperText: 'Ex: Ajustement, Réception, Perte, etc.',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}


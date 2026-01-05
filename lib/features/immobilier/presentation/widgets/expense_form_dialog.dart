import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/property.dart';
import 'expense_form_fields.dart';
import 'form_dialog.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({
    super.key,
    this.expense,
  });

  final PropertyExpense? expense;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  Property? _selectedProperty;
  DateTime _expenseDate = DateTime.now();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  final _receiptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _expenseDate = e.expenseDate;
      _amountController.text = e.amount.toString();
      _descriptionController.text = e.description;
      _category = e.category;
      _receiptController.text = e.receipt ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une propriété')),
      );
      return;
    }

    try {
      final expense = PropertyExpense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        propertyId: _selectedProperty!.id,
        amount: int.parse(_amountController.text),
        expenseDate: _expenseDate,
        category: _category,
        description: _descriptionController.text.trim(),
        property: _selectedProperty!.address,
        receipt: _receiptController.text.trim().isEmpty
            ? null
            : _receiptController.text.trim(),
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(expenseControllerProvider);
      if (widget.expense == null) {
        await controller.createExpense(expense);
      } else {
        await controller.updateExpense(expense);
      }

      if (mounted) {
        ref.invalidate(expensesProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense == null
                  ? 'Dépense enregistrée avec succès'
                  : 'Dépense mise à jour avec succès',
            ),
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
    final propertiesAsync = ref.watch(propertiesProvider);

    return FormDialog(
      title: widget.expense == null ? 'Nouvelle dépense' : 'Modifier la dépense',
      saveLabel: widget.expense == null ? 'Enregistrer' : 'Enregistrer',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            propertiesAsync.when(
              data: (properties) => ExpenseFormFields.propertyField(
                selectedProperty: _selectedProperty,
                properties: properties,
                onChanged: (value) => setState(() => _selectedProperty = value),
                validator: (value) {
                  if (value == null) return 'La propriété est requise';
                  return null;
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement'),
            ),
            const SizedBox(height: 16),
            ExpenseFormFields.dateField(
              expenseDate: _expenseDate,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            ExpenseFormFields.descriptionField(
              controller: _descriptionController,
            ),
            const SizedBox(height: 16),
            ExpenseFormFields.amountField(
              controller: _amountController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le montant est requis';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ExpenseFormFields.categoryField(
              value: _category,
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            ExpenseFormFields.receiptField(
              controller: _receiptController,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


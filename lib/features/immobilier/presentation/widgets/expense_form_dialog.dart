import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/property.dart';
import 'expense_form_fields.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({
    super.key,
    this.expense,
    this.initialProperty,
  });

  final PropertyExpense? expense;
  final Property? initialProperty;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  Property? _selectedProperty;
  DateTime _expenseDate = DateTime.now();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _expenseDate = e.expenseDate;
      _amountController.text = e.amount.toString();
      _descriptionController.text = e.description;
      _category = e.category;
      _receiptPath = e.receipt;
    } else if (widget.initialProperty != null) {
      _selectedProperty = widget.initialProperty;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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
    if (_selectedProperty == null) {
      NotificationService.showWarning(
        context,
        'Veuillez sélectionner une propriété',
      );
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged:
          (_) {}, // Pas besoin de gestion d'état de chargement séparée
      onSubmit: () async {
        final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? 'default';
        final expense = PropertyExpense(
          id: widget.expense?.id ?? IdGenerator.generate(),
          enterpriseId: enterpriseId,
          propertyId: _selectedProperty!.id,
          amount: int.parse(_amountController.text),
          expenseDate: _expenseDate,
          category: _category,
          description: _descriptionController.text.trim(),
          property: _selectedProperty!.address,
          receipt: _receiptPath,
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
        }

        return widget.expense == null
            ? 'Dépense enregistrée avec succès'
            : 'Dépense mise à jour avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return FormDialog(
      title: widget.expense == null
          ? 'Nouvelle dépense'
          : 'Modifier la dépense',
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
              validator: (value) => Validators.amount(value),
            ),
            const SizedBox(height: 16),
            ExpenseFormFields.categoryField(
              value: _category,
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            FormImagePicker(
              initialImagePath: _receiptPath,
              label: 'Photo du reçu',
              onImageSelected: (file) {
                setState(() => _receiptPath = file?.path);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

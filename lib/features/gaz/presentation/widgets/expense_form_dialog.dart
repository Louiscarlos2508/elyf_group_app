import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import 'expense_form/expense_amount_input.dart';
import 'expense_form/expense_category_input.dart';
import 'expense_form/expense_date_input.dart';
import 'expense_form/expense_form_header.dart';

/// Dialog de formulaire pour créer/modifier une dépense.
class GazExpenseFormDialog extends ConsumerStatefulWidget {
  const GazExpenseFormDialog({super.key, this.expense});

  final GazExpense? expense;

  @override
  ConsumerState<GazExpenseFormDialog> createState() =>
      _GazExpenseFormDialogState();
}

class _GazExpenseFormDialogState
    extends ConsumerState<GazExpenseFormDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isFixed = false;
  String? _enterpriseId;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _notesController = TextEditingController(
      text: widget.expense?.notes ?? '',
    );
    if (widget.expense != null) {
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _isFixed = widget.expense!.isFixed;
      _enterpriseId = widget.expense!.enterpriseId;
    } else {
      // TODO: Récupérer enterpriseId depuis le contexte/tenant
      _enterpriseId = 'default_enterprise';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Montant invalide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final expense = GazExpense(
        id: widget.expense?.id ??
            'exp-${DateTime.now().millisecondsSinceEpoch}',
        description: _descriptionController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        enterpriseId: _enterpriseId ?? 'default_enterprise',
        isFixed: _isFixed,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final controller = ref.read(expenseControllerProvider);
      if (widget.expense == null) {
        await controller.addExpense(expense);
      } else {
        await controller.updateExpense(expense);
      }

      if (!mounted) return;

      ref.invalidate(gazExpensesProvider);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.expense == null
                ? 'Dépense créée avec succès'
                : 'Dépense mise à jour',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExpenseFormHeader(isEditing: isEditing),
                  const SizedBox(height: 24),
                  ExpenseAmountInput(controller: _amountController),
                  const SizedBox(height: 16),
                  ExpenseCategoryInput(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) =>
                        setState(() => _selectedCategory = category),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ExpenseDateInput(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Charge fixe'),
                    subtitle: const Text(
                      'Si coché, cette dépense est une charge fixe (ex: loyer). Sinon, c\'est une charge variable.',
                    ),
                    value: _isFixed,
                    onChanged: (value) {
                      setState(() {
                        _isFixed = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optionnel)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: GazButtonStyles.outlined,
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          style: GazButtonStyles.filledPrimary,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(isEditing ? Icons.save : Icons.add),
                          label: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

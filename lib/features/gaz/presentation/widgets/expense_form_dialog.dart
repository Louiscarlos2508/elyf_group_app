import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import 'expense_form/expense_amount_input.dart';
import 'expense_form/expense_category_input.dart';
import 'expense_form/expense_date_input.dart';
import 'expense_form/expense_description_input.dart';
import 'expense_form/expense_fixed_checkbox.dart';
import 'expense_form/expense_form_header.dart';
import 'expense_form/expense_notes_input.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/form_dialog.dart';
import 'package:elyf_groupe_app/shared/utils/form_helper_mixin.dart';

/// Dialog de formulaire pour créer/modifier une dépense.
class GazExpenseFormDialog extends ConsumerStatefulWidget {
  const GazExpenseFormDialog({super.key, this.expense});

  final GazExpense? expense;

  @override
  ConsumerState<GazExpenseFormDialog> createState() =>
      _GazExpenseFormDialogState();
}

class _GazExpenseFormDialogState
    extends ConsumerState<GazExpenseFormDialog> with FormHelperMixin {
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
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(String? enterpriseId) async {
    if (enterpriseId == null) {
      NotificationService.showError(context, 'Aucune entreprise sélectionnée');
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) {
          throw Exception('Montant invalide');
        }

        final expense = GazExpense(
          id: widget.expense?.id ??
              'exp-${DateTime.now().millisecondsSinceEpoch}',
          description: _descriptionController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          enterpriseId: enterpriseId,
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

        if (mounted) {
          ref.invalidate(gazExpensesProvider);
          Navigator.of(context).pop();
        }

        return widget.expense == null
            ? 'Dépense créée avec succès'
            : 'Dépense mise à jour';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    // Récupérer l'ID de l'entreprise active
    final enterpriseId = activeEnterpriseAsync.when(
      data: (enterprise) => enterprise?.id,
      loading: () => null,
      error: (_, __) => null,
    );
    
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
                    onCategoryChanged: (category) {
                      if (category != null) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ExpenseDescriptionInput(controller: _descriptionController),
                  const SizedBox(height: 16),
                  ExpenseDateInput(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: 16),
                  ExpenseFixedCheckbox(
                    value: _isFixed,
                    onChanged: (value) {
                      setState(() {
                        _isFixed = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ExpenseNotesInput(controller: _notesController),
                  const SizedBox(height: 24),
                  FormDialogActions(
                    onCancel: () => Navigator.of(context).pop(),
                    onSubmit: () => _submit(enterpriseId),
                    submitLabel: isEditing ? 'Enregistrer' : 'Ajouter',
                    isLoading: _isLoading,
                    submitEnabled: !_isLoading,
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

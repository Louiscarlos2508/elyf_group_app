import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/tenant/tenant_provider.dart';
import '../../../../core/auth/providers.dart';
import '../../../../../../core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import 'expense_form/expense_amount_input.dart';
import 'expense_form/expense_category_input.dart';
import 'expense_form/expense_date_input.dart';
import 'expense_form/expense_description_input.dart';
import 'expense_form/expense_fixed_checkbox.dart';
import 'expense_form/expense_form_header.dart';
import 'expense_form/expense_notes_input.dart';

/// Dialog de formulaire pour créer/modifier une dépense.
class GazExpenseFormDialog extends ConsumerStatefulWidget {
  const GazExpenseFormDialog({super.key, this.expense});

  final GazExpense? expense;

  @override
  ConsumerState<GazExpenseFormDialog> createState() =>
      _GazExpenseFormDialogState();
}

class _GazExpenseFormDialogState extends ConsumerState<GazExpenseFormDialog>
    with FormHelperMixin {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isFixed = false;
  String? _enterpriseId;
  String? _receiptPath;
  PaymentMethod? _selectedPaymentMethod; // null = pas de déduction auto

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
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    if (widget.expense != null) {
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _isFixed = widget.expense!.isFixed;
      _enterpriseId = widget.expense!.enterpriseId;
      _receiptPath = widget.expense!.receiptPath;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
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
          throw ValidationException(
            'Montant invalide. Le montant doit être supérieur à 0',
            'INVALID_AMOUNT',
          );
        }

        final expense = GazExpense(
          id:
              widget.expense?.id ??
              'exp-${DateTime.now().millisecondsSinceEpoch}',
          description: _descriptionController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          enterpriseId: _enterpriseId ?? enterpriseId,
          isFixed: _isFixed,
          paymentMethod: _selectedPaymentMethod,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          receiptPath: _receiptPath,
        );

        final controller = ref.read(expenseControllerProvider);
        if (widget.expense == null) {
          await controller.addExpense(expense);

          // Auto-déduction trésorerie si mode de paiement choisi
          if (_selectedPaymentMethod != null) {
            try {
              final treasuryRepo = ref.read(gazTreasuryRepositoryProvider);
              final userId = ref.read(authControllerProvider).currentUser?.id ?? 'system';
              final op = TreasuryOperation(
                id: const Uuid().v4(),
                enterpriseId: _enterpriseId ?? enterpriseId,
                userId: userId,
                amount: amount.round(),
                type: TreasuryOperationType.removal,
                fromAccount: _selectedPaymentMethod == PaymentMethod.mobileMoney
                    ? PaymentMethod.mobileMoney
                    : PaymentMethod.cash,
                date: _selectedDate,
                reason: expense.description,
                referenceEntityId: expense.id,
                referenceEntityType: 'gaz_expense',
              );
              await treasuryRepo.saveOperation(op);
              ref.invalidate(gazTreasuryBalanceProvider);
              ref.invalidate(gazTreasuryOperationsStreamProvider);
            } catch (e) {
              // Non-bloquant : la dépense est enregistrée même si la déduction échoue
            }
          }
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
                  FormImagePicker(
                    initialImagePath: _receiptPath,
                    label: 'Photo du reçu',
                    onImageSelected: (file) {
                      setState(() => _receiptPath = file?.path);
                    },
                  ),
                  const SizedBox(height: 24),
                  ExpenseAmountInput(controller: _amountController),
                  const SizedBox(height: 16),
                  ExpenseCategoryInput(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 16),
                  ExpenseDescriptionInput(controller: _descriptionController),
                  const SizedBox(height: 16),
                  ExpenseDateInput(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) =>
                        setState(() => _selectedDate = date),
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
                  const SizedBox(height: 16),
                  // Sélecteur de méthode de paiement pour déduction auto de trésorerie
                  _ExpensePaymentSelector(
                    selected: _selectedPaymentMethod,
                    onChanged: (pm) => setState(() => _selectedPaymentMethod = pm),
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sélecteur méthode de paiement (dépenses)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensePaymentSelector extends StatelessWidget {
  const _ExpensePaymentSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod? selected;
  final void Function(PaymentMethod?) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_outlined, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Déduire de la trésorerie',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Si vous sélectionnez une méthode, un retrait sera automatiquement créé dans la trésorerie.',
              child: Icon(Icons.info_outline, size: 14, color: theme.colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Aucun'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
              avatar: const Icon(Icons.block, size: 14),
            ),
            FilterChip(
              label: const Text('Espèces'),
              selected: selected == PaymentMethod.cash,
              onSelected: (_) => onChanged(PaymentMethod.cash),
              avatar: const Icon(Icons.payments_outlined, size: 14),
            ),
            FilterChip(
              label: const Text('Orange Money'),
              selected: selected == PaymentMethod.mobileMoney,
              onSelected: (_) => onChanged(PaymentMethod.mobileMoney),
              avatar: const Icon(Icons.account_balance_wallet_outlined, size: 14),
            ),
          ],
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Un retrait sera enregistré dans la caisse ${selected == PaymentMethod.mobileMoney ? "Orange Money" : "Espèces"}.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

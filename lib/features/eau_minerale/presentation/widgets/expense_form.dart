import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/expense_record.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Form for creating/editing an expense record.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({super.key, this.expense});

  final ExpenseRecord? expense;

  @override
  ConsumerState<ExpenseForm> createState() => ExpenseFormState();
}

class ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.carburant;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final expense = widget.expense!;
      _labelController.text = expense.label;
      _amountController.text = expense.amountCfa.toString();
      _category = expense.category;
      _selectedDate = expense.date;
      _notesController.text = expense.notes ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final expense = ExpenseRecord(
        id: widget.expense?.id ?? '',
        label: _labelController.text.trim(),
        amountCfa: int.parse(_amountController.text),
        category: _category,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: widget.expense != null ? DateTime.now() : null,
      );

      if (widget.expense == null) {
        await ref.read(financesControllerProvider).createExpense(expense);
      } else {
        await ref.read(financesControllerProvider).updateExpense(expense);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(financesStateProvider);
      NotificationService.showSuccess(
        context,
        widget.expense == null ? 'Dépense enregistrée' : 'Dépense modifiée',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.carburant:
        return Icons.local_gas_station;
      case ExpenseCategory.reparations:
        return Icons.build;
      case ExpenseCategory.achatsDivers:
        return Icons.shopping_cart;
      case ExpenseCategory.autres:
        return Icons.more_horiz;
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
            // Motif (Label)
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Motif de la dépense',
                prefixIcon: Icon(Icons.receipt_long),
                helperText: 'Description détaillée de la dépense',
                hintText: 'Ex: Carburant pour livraison, Réparation pompe...',
              ),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Le motif est requis' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Category
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Type de dépense',
                prefixIcon: Icon(Icons.category),
                helperText: 'Sélectionnez le type de dépense',
              ),
              items: ExpenseCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(category.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            // Date selection
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date de la dépense',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatDate(_selectedDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant (CFA)',
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Montant de la dépense en francs CFA',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final amount = int.tryParse(v);
                if (amount == null || amount <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.note),
                helperText: 'Informations complémentaires sur cette dépense',
                hintText: 'Ex: Fournisseur, numéro de facture...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

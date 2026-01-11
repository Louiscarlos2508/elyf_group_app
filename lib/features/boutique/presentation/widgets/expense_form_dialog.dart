import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart' as shared;
import '../../application/providers.dart';
import '../../domain/entities/expense.dart';

/// Dialog pour créer une dépense dans le module Boutique.
class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({super.key});

  @override
  ConsumerState<ExpenseFormDialog> createState() =>
      _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  bool _isLoading = false;

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.stock:
        return 'Stock/Achats';
      case ExpenseCategory.rent:
        return 'Loyer';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.other:
        return 'Autres';
    }
  }

  Future<String?> _handleSave({
    required double amount,
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    String? notes,
  }) async {
    setState(() => _isLoading = true);
    try {
      final expense = Expense(
        id: 'expense-${DateTime.now().millisecondsSinceEpoch}',
        label: description,
        amountCfa: amount.toInt(),
        category: category,
        date: date,
        notes: notes,
      );

      await ref.read(storeControllerProvider).createExpense(expense);

      if (!mounted) return null;
      ref.invalidate(expensesProvider);
      return null; // Succès
    } catch (e) {
      if (!mounted) return null;
      return 'Erreur: ${e.toString()}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return shared.ExpenseFormDialog<ExpenseCategory>(
      title: 'Nouvelle Dépense',
      categories: ExpenseCategory.values,
      getCategoryLabel: _getCategoryLabel,
      onSave: _handleSave,
      descriptionLabel: 'Libellé',
      isLoading: _isLoading,
    );
  }
}


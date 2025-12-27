import 'package:flutter/material.dart';

import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/entities/expense.dart';

/// Dialog pour afficher les détails d'une dépense.
class ExpenseDetailDialog extends StatelessWidget {
  const ExpenseDetailDialog({
    super.key,
    required this.expense,
  });

  final GazExpense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(expense.description),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            theme: theme,
            label: 'Montant',
            value: CurrencyFormatter.formatDouble(expense.amount),
          ),
          _DetailRow(
            theme: theme,
            label: 'Catégorie',
            value: expense.category.label,
          ),
          _DetailRow(
            theme: theme,
            label: 'Date',
            value: '${expense.date.day}/${expense.date.month}/${expense.date.year}',
          ),
          if (expense.notes != null)
            _DetailRow(
              theme: theme,
              label: 'Notes',
              value: expense.notes!,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.theme,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


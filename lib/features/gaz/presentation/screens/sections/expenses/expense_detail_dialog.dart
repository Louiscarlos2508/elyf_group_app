import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../domain/entities/expense.dart';

/// Dialog pour afficher les détails d'une dépense.
class ExpenseDetailDialog extends StatelessWidget {
  const ExpenseDetailDialog({super.key, required this.expense});

  final GazExpense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        expense.description,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              theme: theme,
              label: 'Montant',
              value: CurrencyFormatter.formatDouble(expense.amount),
              valueColor: theme.colorScheme.error,
            ),
            _DetailRow(
              theme: theme,
              label: 'Catégorie',
              value: expense.category.label,
            ),
            _DetailRow(
              theme: theme,
              label: 'Date',
              value: DateFormat('dd/MM/yyyy').format(expense.date),
            ),
            if (expense.notes != null)
              _DetailRow(theme: theme, label: 'Notes', value: expense.notes!),
            if (expense.receiptPath != null) ...[
              const SizedBox(height: 16),
              Text(
                'Reçu',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(expense.receiptPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElyfButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: ElyfButtonVariant.text,
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
    this.valueColor,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

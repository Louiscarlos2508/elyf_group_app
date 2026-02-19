import 'package:flutter/material.dart';

/// En-tête du formulaire de dépense.
class ExpenseFormHeader extends StatelessWidget {
  const ExpenseFormHeader({super.key, required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long, color: theme.colorScheme.error),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            isEditing ? 'Modifier la dépense' : 'Nouvelle dépense',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

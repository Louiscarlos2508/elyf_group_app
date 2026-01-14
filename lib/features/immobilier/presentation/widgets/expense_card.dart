import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/expense.dart';

/// Carte réutilisable pour afficher une dépense.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense, this.onTap});

  final PropertyExpense expense;
  final VoidCallback? onTap;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.repair:
        return 'Réparation';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.insurance:
        return 'Assurance';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.cleaning:
        return 'Nettoyage';
      case ExpenseCategory.other:
        return 'Autre';
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.repair:
        return Icons.handyman;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.insurance:
        return Icons.shield;
      case ExpenseCategory.taxes:
        return Icons.receipt;
      case ExpenseCategory.cleaning:
        return Icons.cleaning_services;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: theme.colorScheme.onErrorContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryLabel(expense.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatFCFA(expense.amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(expense.expenseDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (expense.property != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.home,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        expense.property!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

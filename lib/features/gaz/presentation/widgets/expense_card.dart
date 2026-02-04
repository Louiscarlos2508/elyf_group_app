import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/expense.dart';

/// Carte affichant les détails d'une dépense.
class GazExpenseCard extends StatelessWidget {
  const GazExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  final GazExpense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  IconData _getCategoryIcon() {
    switch (expense.category) {
      case ExpenseCategory.transport:
        return Icons.local_shipping;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.salaries:
        return Icons.people;
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.supplies:
        return Icons.inventory;
      case ExpenseCategory.structureCharges:
        return Icons.business;
      case ExpenseCategory.loadingEvents:
        return Icons.local_shipping;
      case ExpenseCategory.other:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor() {
    switch (expense.category) {
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.maintenance:
        return const Color(0xFFF59E0B); // Amber
      case ExpenseCategory.salaries:
        return const Color(0xFF8B5CF6); // Violet
      case ExpenseCategory.rent:
        return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.utilities:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.supplies:
        return const Color(0xFF06B6D4); // Cyan
      case ExpenseCategory.structureCharges:
        return const Color(0xFF6366F1); // Indigo
      case ExpenseCategory.loadingEvents:
        return const Color(0xFF14B8A6); // Teal
      case ExpenseCategory.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: categoryColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(), color: categoryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            expense.category.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(expense.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(
                      expense.amount,
                    ).replaceAll(' FCFA', ' F'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: onEdit,
                        tooltip: 'Modifier',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Supprimer',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

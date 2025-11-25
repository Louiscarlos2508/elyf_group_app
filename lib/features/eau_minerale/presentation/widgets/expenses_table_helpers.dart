import 'package:flutter/material.dart';

import '../../domain/entities/expense_record.dart';

/// Helper widgets for expenses table.
class ExpensesTableHelpers {
  static String getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.logistics:
        return 'Logistique';
      case ExpenseCategory.payroll:
        return 'Salaires';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.utility:
        return 'Services';
    }
  }

  static Widget buildCategoryChip(BuildContext context, ExpenseCategory category) {
    final theme = Theme.of(context);
    final categoryName = getCategoryName(category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoryName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget buildActionButtons(
    BuildContext context,
    ExpenseRecord expense,
    void Function(ExpenseRecord expense, String action)? onActionTap,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          onPressed: () => onActionTap?.call(expense, 'view'),
          tooltip: 'Voir',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => onActionTap?.call(expense, 'edit'),
          tooltip: 'Modifier',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}


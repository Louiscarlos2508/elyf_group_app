import 'package:flutter/material.dart';

import '../../domain/entities/expense.dart';

/// Widget pour les filtres de dépenses.
class ExpenseFilters extends StatelessWidget {
  const ExpenseFilters({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;
  final VoidCallback onClear;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilter = selectedCategory != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PopupMenuButton<ExpenseCategory?>(
                    initialValue: selectedCategory,
                    onSelected: onCategoryChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem<ExpenseCategory?>(
                        value: null,
                        child: Text('Toutes les catégories'),
                      ),
                      ...ExpenseCategory.values.map(
                        (category) => PopupMenuItem<ExpenseCategory?>(
                          value: category,
                          child: Text(_getCategoryLabel(category)),
                        ),
                      ),
                    ],
                    child: Chip(
                      label: Text(
                        selectedCategory != null
                            ? _getCategoryLabel(selectedCategory!)
                            : 'Catégorie',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedCategory != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedCategory != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      avatar: selectedCategory != null
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      backgroundColor: selectedCategory != null
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasFilter)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }
}


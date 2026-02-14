import 'package:flutter/material.dart';

import '../../domain/entities/expense.dart';
import '../../application/providers/filter_providers.dart';

/// Widget pour les filtres de dépenses.
class ExpenseFilters extends StatelessWidget {
  const ExpenseFilters({
    super.key,
    required this.selectedCategory,
    required this.selectedArchiveFilter,
    required this.onCategoryChanged,
    required this.onArchiveFilterChanged,
    required this.onClear,
  });

  final ExpenseCategory? selectedCategory;
  final ArchiveFilter selectedArchiveFilter;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;
  final ValueChanged<ArchiveFilter> onArchiveFilterChanged;
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

  String _getArchiveLabel(ArchiveFilter filter) {
    switch (filter) {
      case ArchiveFilter.active:
        return 'Actifs';
      case ArchiveFilter.archived:
        return 'Archivés';
      case ArchiveFilter.all:
        return 'Tous';
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
                   _FilterChip<ArchiveFilter>(
                    label: 'Affichage',
                    value: selectedArchiveFilter,
                    options: ArchiveFilter.values,
                    getLabel: _getArchiveLabel,
                    onChanged: (v) => onArchiveFilterChanged(v ?? ArchiveFilter.active),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
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
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.getLabel,
    required this.onChanged,
    this.showCheckmark = true,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) getLabel;
  final ValueChanged<T?> onChanged;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = true;

    return PopupMenuButton<T?>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem<T?>(
                value: option,
                child: Text(getLabel(option)),
              ))
          .toList(),
      child: Chip(
        label: Text(
          getLabel(value),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        avatar: isSelected && showCheckmark
            ? Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.primary,
              )
            : null,
        backgroundColor: theme.colorScheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

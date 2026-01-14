import 'package:flutter/material.dart';

import '../../domain/entities/expense.dart';

/// Table widget for displaying gaz expenses list - style eau_minerale.
class GazExpensesTable extends StatelessWidget {
  const GazExpensesTable({
    super.key,
    required this.expenses,
    required this.formatCurrency,
    this.onActionTap,
  });

  final List<GazExpense> expenses;
  final String Function(double) formatCurrency;
  final void Function(GazExpense expense, String action)? onActionTap;

  String _getCategoryLabel(ExpenseCategory category) {
    return category.label;
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
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
        return Icons.category;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.maintenance:
        return Colors.orange;
      case ExpenseCategory.salaries:
        return Colors.purple;
      case ExpenseCategory.rent:
        return Colors.brown;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.supplies:
        return Colors.teal;
      case ExpenseCategory.structureCharges:
        return Colors.indigo;
      case ExpenseCategory.loadingEvents:
        return Colors.cyan;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          "Aucune dépense enregistrée aujourd'hui",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return _buildDesktopTable(theme);
        }
        return _buildMobileList(theme);
      },
    );
  }

  Widget _buildDesktopTable(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest,
        ),
        columns: const [
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Catégorie')),
          DataColumn(label: Text('Montant'), numeric: true),
          DataColumn(label: Text('Actions')),
        ],
        rows: expenses.map((expense) {
          final color = _getCategoryColor(expense.category);
          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getCategoryIcon(expense.category),
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expense.description,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getCategoryLabel(expense.category),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  formatCurrency(expense.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () => onActionTap?.call(expense, 'view'),
                      tooltip: 'Voir',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => onActionTap?.call(expense, 'delete'),
                      tooltip: 'Supprimer',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final color = _getCategoryColor(expense.category);

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            expense.description,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _getCategoryLabel(expense.category),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
          trailing: Text(
            formatCurrency(expense.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          onTap: () => onActionTap?.call(expense, 'view'),
        );
      },
    );
  }
}

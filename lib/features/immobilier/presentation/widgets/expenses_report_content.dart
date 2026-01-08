import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/expense.dart';

/// Expenses report content for immobilier.
class ExpensesReportContent extends ConsumerWidget {
  const ExpensesReportContent({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        final periodExpenses = expenses.where((e) {
          return e.expenseDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              e.expenseDate.isBefore(endDate.add(const Duration(days: 1)));
        }).toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

        if (periodExpenses.isEmpty) {
          return _buildEmptyState(theme, 'Aucune dépense sur cette période');
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return _buildDataTable(theme, periodExpenses);
              }
              return _buildMobileList(theme, periodExpenses);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState(theme, 'Erreur de chargement'),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(ThemeData theme, List<PropertyExpense> expenses) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest,
        ),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Catégorie')),
          DataColumn(label: Text('Propriété')),
          DataColumn(label: Text('Montant'), numeric: true),
        ],
        rows: expenses.map((expense) {
          final color = _getCategoryColor(expense.category);
          return DataRow(
            cells: [
              DataCell(Text(_formatDate(expense.expenseDate))),
              DataCell(Text(expense.description)),
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
              DataCell(Text(expense.property ?? '-')),
              DataCell(
                Text(
                  _formatCurrency(expense.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(ThemeData theme, List<PropertyExpense> expenses) {
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCategoryLabel(expense.category),
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
              Text(
                _formatDate(expense.expenseDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: Text(
            _formatCurrency(expense.amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
        return 'Autres';
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
        return Icons.security;
      case ExpenseCategory.taxes:
        return Icons.receipt;
      case ExpenseCategory.cleaning:
        return Icons.cleaning_services;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return Colors.orange;
      case ExpenseCategory.repair:
        return Colors.red;
      case ExpenseCategory.utilities:
        return Colors.blue;
      case ExpenseCategory.insurance:
        return Colors.green;
      case ExpenseCategory.taxes:
        return Colors.purple;
      case ExpenseCategory.cleaning:
        return Colors.teal;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}

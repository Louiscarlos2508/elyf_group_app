import 'package:flutter/material.dart';

import '../../domain/entities/expense_record.dart';
import 'expenses_table_helpers.dart';

/// Desktop table view for expenses.
class ExpensesTableDesktop extends StatelessWidget {
  const ExpensesTableDesktop({
    super.key,
    required this.expenses,
    required this.formatCurrency,
    this.onActionTap,
  });

  final List<ExpenseRecord> expenses;
  final String Function(int) formatCurrency;
  final void Function(ExpenseRecord expense, String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            children: [
              _buildHeaderCell(context, 'Type'),
              _buildHeaderCell(context, 'Description'),
              _buildHeaderCell(context, 'Montant'),
              _buildHeaderCell(context, 'Actions'),
            ],
          ),
          ...expenses.map((expense) {
            return TableRow(
              children: [
                _buildDataCellWidget(
                  context,
                  ExpensesTableHelpers.buildCategoryChip(context, expense.category),
                ),
                _buildDataCellWidget(
                  context,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expense.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (expense.estLieeAProduction) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Liée à une production',
                          child: Icon(
                            Icons.factory,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildDataCellText(
                  context,
                  '${formatCurrency(expense.amountCfa)} FCFA',
                ),
                _buildDataCellWidget(
                  context,
                  ExpensesTableHelpers.buildActionButtons(
                    context,
                    expense,
                    onActionTap,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDataCellText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDataCellWidget(BuildContext context, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: content,
    );
  }
}


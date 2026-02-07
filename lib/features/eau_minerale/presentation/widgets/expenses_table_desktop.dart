import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
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

    return ElyfCard(
      isGlass: true,
      borderColor: Colors.red.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            children: [
              _buildHeaderCell(context, 'Type'),
              _buildHeaderCell(context, 'Description'),
              _buildHeaderCell(context, 'Montant'),
              _buildHeaderCell(context, 'Actions'),
            ],
          ),
          ...expenses.asMap().entries.map((entry) {
            final expense = entry.value;
            final isLast = entry.key == expenses.length - 1;
            return TableRow(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
              ),
              children: [
                _buildDataCellWidget(
                  context,
                  ExpensesTableHelpers.buildCategoryChip(
                    context,
                    expense.category,
                  ),
                ),
                _buildDataCellWidget(
                  context,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expense.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (expense.estLieeAProduction)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.factory,
                            size: 16,
                            color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildDataCellWidget(
                  context,
                  Text(
                    '${formatCurrency(expense.amountCfa)} CFA',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
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



  Widget _buildDataCellWidget(BuildContext context, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: content,
    );
  }
}

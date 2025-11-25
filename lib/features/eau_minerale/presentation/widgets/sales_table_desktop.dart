import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
import 'sales_table_helpers.dart';

/// Desktop table view for sales.
class SalesTableDesktop extends StatelessWidget {
  const SalesTableDesktop({
    super.key,
    required this.sales,
    required this.formatCurrency,
    this.onActionTap,
  });

  final List<Sale> sales;
  final String Function(int) formatCurrency;
  final void Function(Sale sale, String action)? onActionTap;

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
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(0.8),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1.5),
          6: FlexColumnWidth(1.2),
          7: FlexColumnWidth(1.5),
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
              _buildHeaderCell(context, 'Produit'),
              _buildHeaderCell(context, 'Qté'),
              _buildHeaderCell(context, 'Client'),
              _buildHeaderCell(context, 'Prix Total'),
              _buildHeaderCell(context, 'Payé'),
              _buildHeaderCell(context, 'Reste'),
              _buildHeaderCell(context, 'Statut'),
              _buildHeaderCell(context, 'Actions'),
            ],
          ),
          ...sales.map((sale) {
            return TableRow(
              children: [
                _buildDataCellText(context, sale.productName),
                _buildDataCellText(context, sale.quantity.toString()),
                _buildDataCellText(context, sale.customerName),
                _buildDataCellText(
                  context,
                  '${formatCurrency(sale.totalPrice)} CFA',
                ),
                _buildDataCellText(
                  context,
                  '${formatCurrency(sale.amountPaid)} CFA',
                ),
                _buildDataCellWidget(
                  context,
                  Text(
                    '${formatCurrency(sale.remainingAmount)} CFA',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: sale.remainingAmount > 0
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildDataCellWidget(
                  context,
                  SalesTableHelpers.buildStatusChip(context, sale),
                ),
                _buildDataCellWidget(
                  context,
                  SalesTableHelpers.buildActionButtons(
                    context,
                    sale,
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


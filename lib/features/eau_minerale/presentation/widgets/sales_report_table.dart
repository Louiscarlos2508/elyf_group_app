import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';

/// Sales report table widget.
class SalesReportTable extends StatelessWidget {
  const SalesReportTable({
    super.key,
    required this.sales,
  });

  final List<Sale> sales;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (sales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            'Aucune vente pour cette période',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

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
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1.5),
          5: FlexColumnWidth(1.5),
          6: FlexColumnWidth(1.5),
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
              _buildHeaderCell(context, 'Date'),
              _buildHeaderCell(context, 'Client'),
              _buildHeaderCell(context, 'Produit'),
              _buildHeaderCell(context, 'Qté'),
              _buildHeaderCell(context, 'Total'),
              _buildHeaderCell(context, 'Payé'),
              _buildHeaderCell(context, 'Reste'),
            ],
          ),
          ...sales.map((sale) {
            final remaining = sale.totalPrice - sale.amountPaid;
            return TableRow(
              children: [
                _buildDataCellText(context, _formatDate(sale.date)),
                _buildDataCellText(context, sale.customerName),
                _buildDataCellText(context, sale.productName),
                _buildDataCellText(context, sale.quantity.toString()),
                _buildDataCellText(context, _formatCurrency(sale.totalPrice)),
                _buildDataCellWidget(
                  context,
                  Text(
                    _formatCurrency(sale.amountPaid),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildDataCellWidget(
                  context,
                  Text(
                    _formatCurrency(remaining),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: remaining > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
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


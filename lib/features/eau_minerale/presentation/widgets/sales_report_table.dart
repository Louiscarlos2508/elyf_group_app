import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;
    
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

    if (isWide) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 48,
            ),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              columnWidths: const {
                0: FixedColumnWidth(100), // Date
                1: FixedColumnWidth(150), // Client
                2: FixedColumnWidth(120), // Produit
                3: FixedColumnWidth(60),  // Qté
                4: FixedColumnWidth(120), // Total
                5: FixedColumnWidth(120), // Payé
                6: FixedColumnWidth(120), // Reste
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
                final remaining = sale.remainingAmount;
                return TableRow(
                  children: [
                    _buildDataCellText(context, _formatDate(sale.date)),
                    _buildDataCellText(context, sale.customerName),
                    _buildDataCellText(context, sale.productName),
                    _buildDataCellText(context, sale.quantity.toString()),
                    _buildDataCellText(context, CurrencyFormatter.formatFCFA(sale.totalPrice)),
                    _buildDataCellWidget(
                      context,
                      Text(
                        CurrencyFormatter.formatFCFA(sale.amountPaid),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildDataCellWidget(
                      context,
                      Text(
                        CurrencyFormatter.formatFCFA(remaining),
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
          ),
        ),
      );
    }

    // Mobile: Liste de cartes
    return Column(
      children: sales.map((sale) {
        final remaining = sale.remainingAmount;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sale.productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: remaining > 0
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      remaining > 0 ? 'Crédit' : 'Payé',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: remaining > 0 ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMobileInfoRow(
                context,
                Icons.person_outline,
                'Client',
                sale.customerName,
              ),
              const SizedBox(height: 4),
              _buildMobileInfoRow(
                context,
                Icons.calendar_today,
                'Date',
                _formatDate(sale.date),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMobileStatCard(
                      context,
                      'Quantité',
                      sale.quantity.toString(),
                      Icons.numbers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMobileStatCard(
                      context,
                      'Total',
                      '${CurrencyFormatter.formatFCFA(sale.totalPrice)} F',
                      Icons.receipt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMobileStatCard(
                      context,
                      'Payé',
                      '${CurrencyFormatter.formatFCFA(sale.amountPaid)} F',
                      Icons.payment,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMobileStatCard(
                      context,
                      'Reste',
                      '${CurrencyFormatter.formatFCFA(remaining)} F',
                      Icons.account_balance_wallet,
                      color: remaining > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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

  Widget _buildMobileInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final statColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: statColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../../../shared.dart';
import '../../../domain/entities/gas_sale.dart';
import 'sales_report_helpers.dart';

/// Liste des ventes récentes.
class SalesReportRecentSales extends StatelessWidget {
  const SalesReportRecentSales({
    super.key,
    required this.sales,
  });

  final List<GasSale> sales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventes Récentes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (sales.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Aucune vente pour cette période',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...sales.take(10).map((sale) => _SaleRow(theme: theme, sale: sale)),
      ],
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.theme,
    required this.sale,
  });

  final ThemeData theme;
  final GasSale sale;

  @override
  Widget build(BuildContext context) {
    final formattedDate = SalesReportHelpers.formatSaleDate(sale);
    final isRetail = sale.saleType == SaleType.retail;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRetail
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isRetail ? Icons.store : Icons.local_shipping,
                size: 20,
                color: isRetail ? Colors.orange : Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.saleType == SaleType.wholesale &&
                            sale.wholesalerName != null
                        ? sale.wholesalerName!
                        : sale.customerName ?? 'Client anonyme',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (sale.saleType == SaleType.wholesale && sale.tourId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tour d\'approvisionnement',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sale.saleType == SaleType.wholesale &&
                      sale.wholesalerName != null &&
                      sale.customerName != null &&
                      sale.customerName != sale.wholesalerName) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Client: ${sale.customerName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatDouble(sale.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (sale.quantity > 1)
                  Text(
                    '${sale.quantity} × ${CurrencyFormatter.formatDouble(sale.unitPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


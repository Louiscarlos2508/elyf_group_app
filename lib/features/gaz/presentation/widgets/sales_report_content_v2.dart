import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/report_data.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// Content widget for sales report tab - style eau_minerale.
class GazSalesReportContentV2 extends ConsumerWidget {
  const GazSalesReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

)+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) +
        ' F';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      ) as ({
          GazReportPeriod period,
          DateTime? startDate,
          DateTime? endDate,
        })),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: reportDataAsync.when(
        data: (reportData) {
          return salesAsync.when(
            data: (sales) {
              // Filter sales by period
              final filteredSales = sales.where((s) {
                return s.saleDate
                        .isAfter(startDate.subtract(const Duration(days: 1))) &&
                    s.saleDate.isBefore(endDate.add(const Duration(days: 1)));
              }).toList();

              // Group by type
              final retailSales = filteredSales
                  .where((s) => s.saleType == SaleType.retail)
                  .toList();
              final wholesaleSales = filteredSales
                  .where((s) => s.saleType == SaleType.wholesale)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Détail des Ventes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${reportData.salesCount} ventes • Total: ${CurrencyFormatter.formatDouble(reportData.salesRevenue)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ventes par type
                  Text(
                    'Répartition par Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeCard(
                          theme,
                          'Détail',
                          retailSales.length,
                          retailSales.fold<double>(
                            0,
                            (sum, s) => sum + s.totalAmount,
                          ),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTypeCard(
                          theme,
                          'Gros',
                          wholesaleSales.length,
                          wholesaleSales.fold<double>(
                            0,
                            (sum, s) => sum + s.totalAmount,
                          ),
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Liste des ventes récentes
                  Text(
                    'Ventes Récentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredSales.isEmpty)
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
                    ...filteredSales
                        .take(10)
                        .map((sale) => _buildSaleRow(theme, sale)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTypeCard(
    ThemeData theme,
    String type,
    int count,
    double total,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatDouble(total),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count vente${count > 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleRow(ThemeData theme, GasSale sale) {
    final formattedDate =
        '${sale.saleDate.day.toString().padLeft(2, '0')}/${sale.saleDate.month.toString().padLeft(2, '0')}/${sale.saleDate.year} ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sale.saleType == SaleType.retail
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sale.saleType == SaleType.retail
                  ? Icons.store
                  : Icons.local_shipping,
              size: 20,
              color: sale.saleType == SaleType.retail
                  ? Colors.orange
                  : Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName ?? 'Client anonyme',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatDouble(sale.totalAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
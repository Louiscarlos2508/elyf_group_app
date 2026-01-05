import 'package:flutter/material.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/gas_sale.dart';

/// Statistiques des ventes en gros.
class SalesReportWholesaleStats extends StatelessWidget {
  const SalesReportWholesaleStats({
    super.key,
    required this.wholesaleSales,
  });

  final List<GasSale> wholesaleSales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesByTour = _groupSalesByTour(wholesaleSales);
    final salesByWholesaler = _groupSalesByWholesaler(wholesaleSales);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (salesByTour.isNotEmpty) ...[
          _buildTourStats(theme, salesByTour),
          const SizedBox(height: 16),
        ],
        if (salesByWholesaler.isNotEmpty) _buildWholesalerStats(theme, salesByWholesaler),
      ],
    );
  }

  Widget _buildTourStats(
    ThemeData theme,
    Map<String, List<GasSale>> salesByTour,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Par Tour d\'Approvisionnement',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...salesByTour.entries.map((entry) {
          final tourSales = entry.value;
          final total = tourSales.fold<double>(
            0,
            (sum, s) => sum + s.totalAmount,
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tour ${entry.key.substring(0, 8)}...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatDouble(total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tourSales.length} vente${tourSales.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWholesalerStats(
    ThemeData theme,
    Map<String, ({String name, List<GasSale> sales})> salesByWholesaler,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Par Grossiste',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...salesByWholesaler.entries.map((entry) {
          final wholesalerData = entry.value;
          final total = wholesalerData.sales.fold<double>(
            0,
            (sum, s) => sum + s.totalAmount,
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wholesalerData.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatDouble(total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${wholesalerData.sales.length} vente${wholesalerData.sales.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Map<String, List<GasSale>> _groupSalesByTour(List<GasSale> sales) {
    final result = <String, List<GasSale>>{};
    for (final sale in sales) {
      if (sale.tourId != null) {
        result.putIfAbsent(sale.tourId!, () => []).add(sale);
      }
    }
    return result;
  }

  Map<String, ({String name, List<GasSale> sales})> _groupSalesByWholesaler(
    List<GasSale> sales,
  ) {
    final result = <String, ({String name, List<GasSale> sales})>{};
    for (final sale in sales) {
      if (sale.wholesalerId != null && sale.wholesalerName != null) {
        if (!result.containsKey(sale.wholesalerId!)) {
          result[sale.wholesalerId!] = (
            name: sale.wholesalerName!,
            sales: <GasSale>[],
          );
        }
        result[sale.wholesalerId!]!.sales.add(sale);
      }
    }
    return result;
  }
}


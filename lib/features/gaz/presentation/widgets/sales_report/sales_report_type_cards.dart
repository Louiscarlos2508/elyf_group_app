import 'package:flutter/material.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/gas_sale.dart';

/// Cartes affichant les statistiques par type de vente (détail/gros).
class SalesReportTypeCards extends StatelessWidget {
  const SalesReportTypeCards({
    super.key,
    required this.retailSales,
    required this.wholesaleSales,
  });

  final List<GasSale> retailSales;
  final List<GasSale> wholesaleSales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: _TypeCard(
                theme: theme,
                type: 'Détail',
                count: retailSales.length,
                total: _calculateTotal(retailSales),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TypeCard(
                theme: theme,
                type: 'Gros',
                count: wholesaleSales.length,
                total: _calculateTotal(wholesaleSales),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateTotal(List<GasSale> sales) {
    return sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.theme,
    required this.type,
    required this.count,
    required this.total,
    required this.color,
  });

  final ThemeData theme;
  final String type;
  final int count;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}


import 'package:flutter/material.dart';

import '../../../domain/entities/report_data.dart';

/// Indicateurs de performance du rapport de profit.
class ProfitPerformanceIndicators extends StatelessWidget {
  const ProfitPerformanceIndicators({
    super.key,
    required this.data,
  });

  final GazReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marginPercentage = data.profitMarginPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildIndicatorRow(
            theme,
            'Taux de Marge',
            '${marginPercentage.toStringAsFixed(2)}%',
            marginPercentage >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow(
            theme,
            'Nombre de Ventes',
            '${data.salesCount}',
            theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow(
            theme,
            'Nombre de Dépenses',
            '${data.expensesCount}',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/report_data.dart';

/// Détail des calculs du rapport de profit.
class ProfitCalculationDetail extends StatelessWidget {
  const ProfitCalculationDetail({
    super.key,
    required this.data,
  });

  final GazReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildCalculationRow(
            theme,
            "Chiffre d'Affaires",
            CurrencyFormatter.formatDouble(data.salesRevenue),
            Colors.blue,
          ),
          const Divider(),
          _buildCalculationRow(
            theme,
            'Dépenses',
            CurrencyFormatter.formatDouble(data.expensesAmount),
            Colors.red,
          ),
          const Divider(),
          _buildCalculationRow(
            theme,
            'Bénéfice Net',
            CurrencyFormatter.formatDouble(data.profit),
            data.profit >= 0 ? Colors.green : Colors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    ThemeData theme,
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


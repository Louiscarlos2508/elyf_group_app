import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/report_data.dart';

/// En-tête du rapport de vente avec titre et résumé.
class SalesReportHeader extends StatelessWidget {
  const SalesReportHeader({super.key, required this.reportData});

  final GazReportData reportData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      ],
    );
  }
}

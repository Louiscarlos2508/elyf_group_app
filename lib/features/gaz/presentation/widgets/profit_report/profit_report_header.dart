import 'package:flutter/material.dart';

import '../../../domain/entities/report_data.dart';

/// En-tête du rapport de profit.
class ProfitReportHeader extends StatelessWidget {
  const ProfitReportHeader({
    super.key,
    required this.data,
  });

  final GazReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfitable = data.profit >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse de Rentabilité',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isProfitable
              ? 'Votre activité est rentable sur cette période'
              : 'Attention: Déficit sur cette période',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isProfitable ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

/// KPI cards row for reports screen.
class ReportKpiCards extends StatelessWidget {
  const ReportKpiCards({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final totalTransactions = stats['totalTransactions'] as int? ?? 0;
    final totalCommission = stats['totalCommission'] as int? ?? 0;
    final depositsCount = stats['depositsCount'] as int? ?? 0;
    final withdrawalsCount = stats['withdrawalsCount'] as int? ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElyfStatsCard(
                label: 'Transactions',
                value: totalTransactions.toString(),
                icon: Icons.history_rounded,
                color: AppColors.primary,
                isGlass: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElyfStatsCard(
                label: 'Commissions',
                value: CurrencyFormatter.formatFCFA(totalCommission),
                icon: Icons.payments_rounded,
                color: AppColors.success,
                isGlass: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElyfStatsCard(
                label: 'Dépôts',
                value: depositsCount.toString(),
                icon: Icons.south_west_rounded,
                color: const Color(0xFFFF6B00),
                isGlass: true,
                subtitle: CurrencyFormatter.formatFCFA(cashInTotal),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElyfStatsCard(
                label: 'Retraits',
                value: withdrawalsCount.toString(),
                icon: Icons.north_east_rounded,
                color: AppColors.danger,
                isGlass: true,
                subtitle: CurrencyFormatter.formatFCFA(cashOutTotal),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual KPI card for reports.

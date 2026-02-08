import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// Section des KPI cards pour les dépenses.
class ExpensesKpiSection extends StatelessWidget {
  const ExpensesKpiSection({
    super.key,
    required this.todayTotal,
    required this.todayCount,
    required this.totalExpenses,
    required this.totalCount,
  });

  final double todayTotal;
  final int todayCount;
  final double totalExpenses;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  child: ElyfStatsCard(
                    label: 'Dépenses du jour',
                    value: CurrencyFormatter.formatDouble(todayTotal),
                    subtitle: '$todayCount dépense(s)',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFFF54900),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElyfStatsCard(
                    label: 'Total général',
                    value: CurrencyFormatter.formatDouble(totalExpenses),
                    subtitle: '$totalCount dépense(s)',
                    icon: Icons.trending_down,
                    color: const Color(0xFFE7000B),
                  ),
                ),
              ],
            );
          }

          // Mobile: stack vertically
          return Column(
            children: [
              ElyfStatsCard(
                label: 'Dépenses du jour',
                value: CurrencyFormatter.formatDouble(todayTotal),
                subtitle: '$todayCount dépense(s)',
                icon: Icons.account_balance_wallet,
                color: const Color(0xFFF54900),
              ),
              SizedBox(height: AppSpacing.md),
              ElyfStatsCard(
                label: 'Total général',
                value: CurrencyFormatter.formatDouble(totalExpenses),
                subtitle: '$totalCount dépense(s)',
                icon: Icons.trending_down,
                color: const Color(0xFFE7000B),
              ),
            ],
          );
        },
      ),
    );
  }
}

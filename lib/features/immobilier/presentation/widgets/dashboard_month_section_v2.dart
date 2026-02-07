import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import 'dashboard_kpi_card_v2.dart';

/// Section displaying monthly KPIs for immobilier.
class DashboardMonthSectionV2 extends StatelessWidget {
  const DashboardMonthSectionV2({
    super.key,
    required this.monthRevenue,
    required this.monthPaymentsCount,
    required this.monthExpensesAmount,
    required this.monthProfit,
    required this.occupancyRate,
    required this.collectionRate, // Added parameter
    this.onRevenueTap,
    this.onExpensesTap,
    this.onProfitTap,
    this.onOccupancyTap,
  });

  final int monthRevenue;
  final int monthPaymentsCount;
  final int monthExpensesAmount;
  final int monthProfit;
  final double occupancyRate;
  final double collectionRate; // Added field
  final VoidCallback? onRevenueTap;
  final VoidCallback? onExpensesTap;
  final VoidCallback? onProfitTap;
  final VoidCallback? onOccupancyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          DashboardKpiCardV2(
            label: 'Revenus Locatifs',
            value: CurrencyFormatter.formatFCFA(monthRevenue),
            subtitle: '$monthPaymentsCount paiements (${collectionRate.toStringAsFixed(0)}%)', // Display rate
            icon: Icons.trending_up,
            iconColor: const Color(0xFF3B82F6), // Blue
            backgroundColor: const Color(0xFF3B82F6),
            onTap: onRevenueTap,
          ),
          DashboardKpiCardV2(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(monthExpensesAmount),
            subtitle: 'Charges',
            icon: Icons.receipt_long,
            iconColor: theme.colorScheme.error,
            backgroundColor: theme.colorScheme.error,
            onTap: onExpensesTap,
          ),
          DashboardKpiCardV2(
            label: 'Bénéfice Net',
            value: CurrencyFormatter.formatFCFA(monthProfit),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthProfit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
            valueColor: monthProfit >= 0
                ? const Color(0xFF059669)
                : theme.colorScheme.error,
            backgroundColor: monthProfit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
            onTap: onProfitTap,
          ),
          DashboardKpiCardV2(
            label: "Taux d'Occupation",
            value: '${occupancyRate.toStringAsFixed(0)}%',
            subtitle: 'propriétés louées',
            icon: Icons.home,
            iconColor: const Color(0xFF6366F1), // Indigo
            backgroundColor: const Color(0xFF6366F1),
            onTap: onOccupancyTap,
          ),
        ];

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

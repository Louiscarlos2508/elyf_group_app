import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

import 'dashboard_kpi_card.dart';

/// Section displaying monthly KPIs for boutique.
class DashboardMonthSection extends StatelessWidget {
  const DashboardMonthSection({
    super.key,
    required this.monthRevenue,
    required this.monthSalesCount,
    required this.monthPurchasesAmount,
    required this.monthExpensesAmount,
    required this.monthProfit,
  });

  final int monthRevenue;
  final int monthSalesCount;
  final int monthPurchasesAmount;
  final int monthExpensesAmount;
  final int monthProfit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          DashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: CurrencyFormatter.formatFCFA(monthRevenue),
            subtitle: '$monthSalesCount ventes',
            icon: Icons.trending_up,
            iconColor: const Color(0xFF3B82F6),
            backgroundColor: const Color(0xFF3B82F6),
          ),
          DashboardKpiCard(
            label: 'Achats',
            value: CurrencyFormatter.formatFCFA(monthPurchasesAmount),
            subtitle: 'Approvisionnements',
            icon: Icons.shopping_bag,
            iconColor: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFF59E0B),
          ),
          DashboardKpiCard(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(monthExpensesAmount),
            subtitle: 'Charges',
            icon: Icons.receipt_long,
            iconColor: theme.colorScheme.error,
            backgroundColor: theme.colorScheme.error,
          ),
          DashboardKpiCard(
            label: 'Bénéfice Net',
            value: CurrencyFormatter.formatFCFA(monthProfit),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthProfit >= 0 ? AppColors.success : theme.colorScheme.error,
            valueColor: monthProfit >= 0
                ? AppColors.success
                : theme.colorScheme.error,
            backgroundColor: monthProfit >= 0 ? AppColors.success : theme.colorScheme.error,
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

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
  });

  final int monthRevenue;
  final int monthPaymentsCount;
  final int monthExpensesAmount;
  final int monthProfit;
  final double occupancyRate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          DashboardKpiCardV2(
            label: 'Revenus Locatifs',
            value: CurrencyFormatter.formatFCFA(monthRevenue),
            subtitle: '$monthPaymentsCount paiements',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCardV2(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(monthExpensesAmount),
            subtitle: 'Charges',
            icon: Icons.receipt_long,
            iconColor: Colors.red,
            backgroundColor: Colors.red,
          ),
          DashboardKpiCardV2(
            label: 'Bénéfice Net',
            value: CurrencyFormatter.formatFCFA(monthProfit),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthProfit >= 0 ? Colors.green : Colors.red,
            valueColor:
                monthProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            backgroundColor: monthProfit >= 0 ? Colors.green : Colors.red,
          ),
          DashboardKpiCardV2(
            label: "Taux d'Occupation",
            value: '${occupancyRate.toStringAsFixed(0)}%',
            subtitle: 'propriétés louées',
            icon: Icons.home,
            iconColor: Colors.indigo,
            backgroundColor: Colors.indigo,
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

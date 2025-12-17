import 'package:flutter/material.dart';

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

  String _formatCurrency(int amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final amountStr = absAmount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < amountStr.length; i++) {
      if (i > 0 && (amountStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(amountStr[i]);
    }
    return '${isNegative ? '-' : ''}$buffer FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          DashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: _formatCurrency(monthRevenue),
            subtitle: '$monthSalesCount ventes',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCard(
            label: 'Achats',
            value: _formatCurrency(monthPurchasesAmount),
            subtitle: 'Approvisionnements',
            icon: Icons.shopping_bag,
            iconColor: Colors.orange,
            backgroundColor: Colors.orange,
          ),
          DashboardKpiCard(
            label: 'Dépenses',
            value: _formatCurrency(monthExpensesAmount),
            subtitle: 'Charges',
            icon: Icons.receipt_long,
            iconColor: Colors.red,
            backgroundColor: Colors.red,
          ),
          DashboardKpiCard(
            label: 'Bénéfice Net',
            value: _formatCurrency(monthProfit),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthProfit >= 0 ? Colors.green : Colors.red,
            valueColor:
                monthProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            backgroundColor: monthProfit >= 0 ? Colors.green : Colors.red,
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

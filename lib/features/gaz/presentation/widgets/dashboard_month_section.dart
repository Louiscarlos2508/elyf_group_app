import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/gas_sale.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying monthly KPIs for gaz module.
class GazDashboardMonthSection extends StatelessWidget {
  const GazDashboardMonthSection({
    super.key,
    required this.monthRevenue,
    required this.monthSalesCount,
    required this.monthExpensesAmount,
    required this.monthProfit,
  });

  final double monthRevenue;
  final int monthSalesCount;
  final double monthExpensesAmount;
  final double monthProfit;


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          GazDashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: CurrencyFormatter.formatDouble(monthRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '$monthSalesCount ventes',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          GazDashboardKpiCard(
            label: 'Dépenses',
            value: CurrencyFormatter.formatDouble(monthExpensesAmount).replaceAll(' FCFA', ' F'),
            subtitle: 'Charges du mois',
            icon: Icons.receipt_long,
            iconColor: Colors.red,
            backgroundColor: Colors.red,
          ),
          GazDashboardKpiCard(
            label: 'Bénéfice Net',
            value: CurrencyFormatter.formatDouble(monthProfit).replaceAll(' FCFA', ' F'),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthProfit >= 0 ? Colors.green : Colors.red,
            valueColor: monthProfit >= 0
                ? Colors.green.shade700
                : Colors.red.shade700,
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
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        );
      },
    );
  }
}
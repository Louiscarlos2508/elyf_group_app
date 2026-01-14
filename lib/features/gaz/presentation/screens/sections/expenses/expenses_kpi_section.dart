import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../widgets/expense_kpi_card.dart';

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
                  child: ExpenseKpiCard(
                    title: 'Dépenses du jour',
                    amount: CurrencyFormatter.formatDouble(todayTotal),
                    count: '$todayCount dépense(s)',
                    icon: Icons.account_balance_wallet,
                    amountColor: const Color(0xFFF54900),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ExpenseKpiCard(
                    title: 'Total général',
                    amount: CurrencyFormatter.formatDouble(totalExpenses),
                    count: '$totalCount dépense(s)',
                    icon: Icons.trending_down,
                    amountColor: const Color(0xFFE7000B),
                  ),
                ),
              ],
            );
          }

          // Mobile: stack vertically
          return Column(
            children: [
              ExpenseKpiCard(
                title: 'Dépenses du jour',
                amount: CurrencyFormatter.formatDouble(todayTotal),
                count: '$todayCount dépense(s)',
                icon: Icons.account_balance_wallet,
                amountColor: const Color(0xFFF54900),
              ),
              const SizedBox(height: 16),
              ExpenseKpiCard(
                title: 'Total général',
                amount: CurrencyFormatter.formatDouble(totalExpenses),
                count: '$totalCount dépense(s)',
                icon: Icons.trending_down,
                amountColor: const Color(0xFFE7000B),
              ),
            ],
          );
        },
      ),
    );
  }
}

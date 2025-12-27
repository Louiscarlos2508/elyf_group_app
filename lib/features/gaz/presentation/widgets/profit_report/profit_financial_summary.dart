import 'package:flutter/material.dart';

import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/entities/report_data.dart';
import '../dashboard_kpi_card.dart';

/// Résumé financier du rapport de profit.
class ProfitFinancialSummary extends StatelessWidget {
  const ProfitFinancialSummary({
    super.key,
    required this.data,
    required this.isWide,
  });

  final GazReportData data;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final isProfitable = data.profit >= 0;

    return isWide
        ? Row(
            children: [
              Expanded(
                child: GazDashboardKpiCard(
                  label: "Chiffre d'Affaires",
                  value: CurrencyFormatter.formatDouble(data.salesRevenue),
                  icon: Icons.trending_up,
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GazDashboardKpiCard(
                  label: 'Dépenses',
                  value: CurrencyFormatter.formatDouble(data.expensesAmount),
                  icon: Icons.receipt_long,
                  iconColor: Colors.red,
                  backgroundColor: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GazDashboardKpiCard(
                  label: 'Bénéfice Net',
                  value: CurrencyFormatter.formatDouble(data.profit),
                  subtitle: isProfitable ? 'Profit' : 'Déficit',
                  icon: Icons.account_balance_wallet,
                  iconColor: isProfitable ? Colors.green : Colors.red,
                  valueColor: isProfitable
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  backgroundColor: isProfitable ? Colors.green : Colors.red,
                ),
              ),
            ],
          )
        : Column(
            children: [
              GazDashboardKpiCard(
                label: "Chiffre d'Affaires",
                value: CurrencyFormatter.formatDouble(data.salesRevenue),
                icon: Icons.trending_up,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: 16),
              GazDashboardKpiCard(
                label: 'Dépenses',
                value: CurrencyFormatter.formatDouble(data.expensesAmount),
                icon: Icons.receipt_long,
                iconColor: Colors.red,
                backgroundColor: Colors.red,
              ),
              const SizedBox(height: 16),
              GazDashboardKpiCard(
                label: 'Bénéfice Net',
                value: CurrencyFormatter.formatDouble(data.profit),
                subtitle: isProfitable ? 'Profit' : 'Déficit',
                icon: Icons.account_balance_wallet,
                iconColor: isProfitable ? Colors.green : Colors.red,
                valueColor: isProfitable
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                backgroundColor: isProfitable ? Colors.green : Colors.red,
              ),
            ],
          );
  }
}


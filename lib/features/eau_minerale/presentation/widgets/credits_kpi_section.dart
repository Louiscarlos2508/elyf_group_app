import 'package:flutter/material.dart';

import 'credit_kpi_card.dart';

/// KPI section for credits screen.
class CreditsKpiSection extends StatelessWidget {
  const CreditsKpiSection({
    super.key,
    required this.totalCredit,
    required this.customersWithCredit,
  });

  final int totalCredit;
  final int customersWithCredit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return isWide
            ? Row(
                children: [
                  Expanded(
                    child: CreditKpiCard(
                      label: 'Total Crédit en Cours',
                      value: totalCredit.toString(),
                      unit: 'FCFA',
                      trend: Icon(
                        Icons.trending_down,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CreditKpiCard(
                      label: 'Clients avec Crédit',
                      value: customersWithCredit.toString(),
                      icon: Icons.person,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  CreditKpiCard(
                    label: 'Total Crédit en Cours',
                    value: totalCredit.toString(),
                    unit: 'FCFA',
                    trend: Icon(
                      Icons.trending_down,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CreditKpiCard(
                    label: 'Clients avec Crédit',
                    value: customersWithCredit.toString(),
                    icon: Icons.person,
                  ),
                ],
              );
      },
    );
  }
}

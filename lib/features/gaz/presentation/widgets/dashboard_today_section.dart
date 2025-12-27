import 'package:flutter/material.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/gas_sale.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying today's KPIs for gaz module.
class GazDashboardTodaySection extends StatelessWidget {
  const GazDashboardTodaySection({
    super.key,
    required this.todaySales,
  });

  final List<GasSale> todaySales;


  @override
  Widget build(BuildContext context) {
    final todayRevenue = todaySales.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    final todayCount = todaySales.length;
    final avgTicket = todayCount > 0 ? todayRevenue / todayCount : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          GazDashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: CurrencyFormatter.formatDouble(todayRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '$todayCount vente(s)',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          GazDashboardKpiCard(
            label: 'Ticket Moyen',
            value: CurrencyFormatter.formatDouble(avgTicket).replaceAll(' FCFA', ' F'),
            subtitle: todayCount > 0 ? 'par transaction' : 'aucune vente',
            icon: Icons.receipt,
            iconColor: Colors.green,
            valueColor: Colors.green.shade700,
            backgroundColor: Colors.green,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }

        return Column(
          children: [cards[0], const SizedBox(height: 16), cards[1]],
        );
      },
    );
  }
}
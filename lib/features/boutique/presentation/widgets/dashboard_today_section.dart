import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying today's KPIs for boutique.
class DashboardTodaySection extends StatelessWidget {
  const DashboardTodaySection({
    super.key,
    required this.todaySales,
  });

  final List<Sale> todaySales;

  String _formatCurrency(int amount) {
    final amountStr = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < amountStr.length; i++) {
      if (i > 0 && (amountStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(amountStr[i]);
    }
    return '$buffer FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final todayRevenue = todaySales.fold(0, (sum, s) => sum + s.totalAmount);
    final todayCount = todaySales.length;
    final avgTicket = todayCount > 0 ? todayRevenue ~/ todayCount : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          DashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: _formatCurrency(todayRevenue),
            subtitle: '$todayCount vente(s)',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCard(
            label: 'Ticket Moyen',
            value: _formatCurrency(avgTicket),
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

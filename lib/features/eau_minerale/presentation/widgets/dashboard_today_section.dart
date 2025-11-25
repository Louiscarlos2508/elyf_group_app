import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
import '../../application/controllers/sales_controller.dart' show SalesState;
import 'dashboard_kpi_card.dart';

/// Section displaying today's KPIs.
class DashboardTodaySection extends StatelessWidget {
  const DashboardTodaySection({
    super.key,
    required this.salesState,
  });

  final SalesState salesState;

  String _formatCurrency(int amount) {
    final amountStr = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < amountStr.length; i++) {
      if (i > 0 && (amountStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(amountStr[i]);
    }
    return '${buffer.toString()} CFA';
  }

  @override
  Widget build(BuildContext context) {
    final todayRevenue = salesState.todayRevenue;
    final todaySalesCount = salesState.sales.length;
    final todayCollections = salesState.sales
        .where((Sale sale) => sale.isFullyPaid)
        .fold(0, (int sum, Sale sale) => sum + sale.amountPaid);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          DashboardKpiCard(
            label: 'Chiffre d\'Affaires',
            value: _formatCurrency(todayRevenue),
            subtitle: '$todaySalesCount vente(s)',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCard(
            label: 'Encaissements',
            value: _formatCurrency(todayCollections),
            subtitle: todayRevenue > 0
                ? '${((todayCollections / todayRevenue) * 100).toStringAsFixed(0)}% collecté'
                : '0% collecté',
            icon: Icons.attach_money,
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


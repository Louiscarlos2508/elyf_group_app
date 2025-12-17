import 'package:flutter/material.dart';

import '../../domain/entities/payment.dart';
import 'dashboard_kpi_card_v2.dart';

/// Section displaying today's KPIs for immobilier.
class DashboardTodaySectionV2 extends StatelessWidget {
  const DashboardTodaySectionV2({
    super.key,
    required this.todayPayments,
  });

  final List<Payment> todayPayments;

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
    final paidPayments =
        todayPayments.where((p) => p.status == PaymentStatus.paid).toList();
    final todayRevenue = paidPayments.fold(0, (sum, p) => sum + p.amount);
    final todayCount = paidPayments.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          DashboardKpiCardV2(
            label: 'Paiements reçus',
            value: _formatCurrency(todayRevenue),
            subtitle: '$todayCount paiement(s)',
            icon: Icons.payments,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCardV2(
            label: 'Nombre de paiements',
            value: todayCount.toString(),
            subtitle: todayCount > 0 ? 'transactions' : 'aucun paiement',
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

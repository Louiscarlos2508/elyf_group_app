import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/payment.dart';
import 'immobilier_kpi_card.dart';

/// Section displaying today's KPIs for immobilier.
class DashboardTodaySectionV2 extends StatelessWidget {
  const DashboardTodaySectionV2({super.key, required this.todayPayments});

  final List<Payment> todayPayments;

  @override
  Widget build(BuildContext context) {
    final paidPayments = todayPayments
        .where((p) => p.status == PaymentStatus.paid || p.status == PaymentStatus.partial)
        .toList();
    final todayRevenue = paidPayments.fold(0, (sum, p) => sum + p.paidAmount);
    final todayCount = paidPayments.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          ImmobilierKpiCard(
            label: 'Paiements reçus',
            value: CurrencyFormatter.formatFCFA(todayRevenue),
            subtitle: '$todayCount paiement(s)',
            icon: Icons.payments,
            color: const Color(0xFF3B82F6), // Blue
          ),
          ImmobilierKpiCard(
            label: 'Nombre de paiements',
            value: todayCount.toString(),
            subtitle: todayCount > 0 ? 'transactions' : 'aucun paiement',
            icon: Icons.receipt,
            color: const Color(0xFF10B981), // Emerald
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

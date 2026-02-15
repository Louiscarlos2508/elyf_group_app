import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../domain/services/boutique_calculation_service.dart';
import 'boutique_kpi_card.dart';

/// Section displaying today's KPIs for boutique.
///
/// Uses [DashboardTodayMetrics] from the calculation service.
class DashboardTodaySection extends StatelessWidget {
  const DashboardTodaySection({super.key, required this.metrics});

  /// Pre-calculated today metrics from [BoutiqueDashboardCalculationService].
  final DashboardTodayMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final todayRevenue = metrics.revenue;
    final todayCount = metrics.salesCount;
    final avgTicket = metrics.averageTicket;
    final itemsCount = metrics.itemsCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cards = [
          BoutiqueKpiCard(
            label: "Chiffre d'Affaires",
            value: CurrencyFormatter.formatFCFA(todayRevenue),
            subtitle: '$todayCount vente(s)',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
          BoutiqueKpiCard(
            label: 'Articles Vendus',
            value: '$itemsCount',
            subtitle: 'quantité totale',
            icon: Icons.inventory_2_outlined,
            color: Colors.orange,
          ),
          BoutiqueKpiCard(
            label: 'Ticket Moyen',
            value: CurrencyFormatter.formatFCFA(avgTicket),
            subtitle: todayCount > 0 ? 'par transaction' : 'aucune vente',
            icon: Icons.receipt,
            color: Colors.green,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
              ],
            ),
            const SizedBox(height: 16),
            cards[1],
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_dashboard_calculation_service.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying today's KPIs for gaz module.
///
/// Uses [GazDashboardTodayMetrics] from the calculation service.
class GazDashboardTodaySection extends StatelessWidget {
  const GazDashboardTodaySection({super.key, required this.metrics});

  /// Pre-calculated today metrics from [GazDashboardCalculationService].
  final GazDashboardTodayMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final todayRevenue = metrics.revenue;
    final todayCount = metrics.salesCount;
    final avgTicket = metrics.averageTicket;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          GazDashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: CurrencyFormatter.formatDouble(
              todayRevenue,
            ).replaceAll(' FCFA', ' F'),
            subtitle: '$todayCount vente(s)',
            icon: Icons.trending_up,
            iconColor: const Color(0xFF3B82F6), // Blue
            backgroundColor: const Color(0xFF3B82F6),
          ),
          GazDashboardKpiCard(
            label: 'Ticket Moyen',
            value: CurrencyFormatter.formatDouble(
              avgTicket,
            ).replaceAll(' FCFA', ' F'),
            subtitle: todayCount > 0 ? 'par transaction' : 'aucune vente',
            icon: Icons.receipt,
            iconColor: const Color(0xFF10B981), // Emerald
            valueColor: const Color(0xFF059669), // Darker emerald
            backgroundColor: const Color(0xFF10B981),
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

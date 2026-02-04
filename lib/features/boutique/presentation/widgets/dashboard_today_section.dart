import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

import '../../domain/services/dashboard_calculation_service.dart';
import 'dashboard_kpi_card.dart';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          DashboardKpiCard(
            label: "Chiffre d'Affaires",
            value: CurrencyFormatter.formatFCFA(todayRevenue),
            subtitle: '$todayCount vente(s)',
            icon: Icons.trending_up,
            iconColor: const Color(0xFF3B82F6),
            backgroundColor: const Color(0xFF3B82F6),
          ),
          DashboardKpiCard(
            label: 'Ticket Moyen',
            value: CurrencyFormatter.formatFCFA(avgTicket),
            subtitle: todayCount > 0 ? 'par transaction' : 'aucune vente',
            icon: Icons.receipt,
            iconColor: AppColors.success,
            valueColor: AppColors.success,
            backgroundColor: AppColors.success,
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

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

import 'dashboard_kpi_card_v2.dart';

/// Section displaying monthly KPIs for immobilier.
class DashboardMonthSectionV2 extends StatelessWidget {
  const DashboardMonthSectionV2({
    super.key,
    required this.monthRevenue,
    required this.monthPaymentsCount,
    required this.monthExpensesAmount,
    required this.monthProfit,
    required this.occupancyRate,
    required this.collectionRate,
    this.unpaidRentsCount = 0,
    this.openTickets = 0,
    this.highPriorityTickets = 0,
    this.onRevenueTap,
    this.onExpensesTap,
    this.onProfitTap,
    this.onOccupancyTap,
    this.onMaintenanceTap,
  });

  final int monthRevenue;
  final int monthPaymentsCount;
  final int monthExpensesAmount;
  final int monthProfit;
  final double occupancyRate;
  final double collectionRate;
  final int unpaidRentsCount;
  final int openTickets;
  final int highPriorityTickets;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onExpensesTap;
  final VoidCallback? onProfitTap;
  final VoidCallback? onOccupancyTap;
  final VoidCallback? onMaintenanceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          DashboardKpiCardV2(
            label: 'Revenus Locatifs',
            value: CurrencyFormatter.formatFCFA(monthRevenue),
            subtitle: '$monthPaymentsCount paiements (${collectionRate.toStringAsFixed(0)}%)',
            icon: Icons.trending_up,
            iconColor: const Color(0xFF3B82F6), // Blue
            backgroundColor: const Color(0xFF3B82F6),
            onTap: onRevenueTap,
          ),
          DashboardKpiCardV2(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(monthExpensesAmount),
            subtitle: 'Charges',
            icon: Icons.receipt_long,
            iconColor: theme.colorScheme.error,
            backgroundColor: theme.colorScheme.error,
            onTap: onExpensesTap,
          ),
          DashboardKpiCardV2(
            label: 'Loyers Impayés',
            value: '$unpaidRentsCount',
            subtitle: 'Contrats en attente',
            icon: Icons.money_off,
            iconColor: unpaidRentsCount > 0 ? theme.colorScheme.error : const Color(0xFF10B981),
            backgroundColor: unpaidRentsCount > 0 ? theme.colorScheme.error : const Color(0xFF10B981),
            onTap: null, // Pas de filtrage spécifique pour l'instant
          ),
          DashboardKpiCardV2(
            label: 'Bénéfice Net',
            value: CurrencyFormatter.formatFCFA(monthProfit),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthProfit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
            valueColor: monthProfit >= 0
                ? const Color(0xFF059669)
                : theme.colorScheme.error,
            backgroundColor: monthProfit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
            onTap: onProfitTap,
          ),
          DashboardKpiCardV2(
            label: "Taux d'Occupation",
            value: '${occupancyRate.toStringAsFixed(0)}%',
            subtitle: 'propriétés louées',
            icon: Icons.home,
            iconColor: const Color(0xFF6366F1), // Indigo
            backgroundColor: const Color(0xFF6366F1),
            onTap: onOccupancyTap,
          ),
             if (openTickets > 0 || onMaintenanceTap != null)
            DashboardKpiCardV2(
              label: 'Maintenance',
              value: '$openTickets tickets',
              subtitle: '$highPriorityTickets urgents',
              icon: Icons.handyman,
              iconColor: highPriorityTickets > 0 ? Colors.red : Colors.orange,
              backgroundColor: highPriorityTickets > 0 ? Colors.red : Colors.orange,
              onTap: onMaintenanceTap,
            ),
        ];

        // Layout logic
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
                if (cards.length > 4) ...[
                   const SizedBox(width: 16),
                   Expanded(child: cards[4]),
                ]
              ],
            ),
          );
        }
        
        // Mobile Layout using Staggered Grid for better packing
        return StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: [
            cards[0],
            cards[1],
            StaggeredGridTile.fit(crossAxisCellCount: 2, child: cards[2]),
            cards[3],
            // Occupancy
             // Recovery (is part of Revenue card in V2 usually or separate?)
             // In the previous file it was just 4 cards. 
             // Wait, the previous file had 4 cards hardcocoded.
             // But the design in my head for StaggeredGrid was different.
             // Let's stick to what was there but add the 5th card if needed.
             // The previous code used Column/Row for mobile.
             // I will use StaggeredGrid which is cleaner.
             
             // Wait, the previous code imported StaggeredGridView not used?
             // No, it imported `dashboard_kpi_card_v2.dart`.
             // I recall seeing `StaggeredGrid` in a previous turn but the `view_file` showed `Column` and `Row`.
             // I will use `StaggeredGrid` here for better layout of 5 items.
             
             if (cards.length > 4)
              cards[4],
          ],
        );
      },
    );
  }
}

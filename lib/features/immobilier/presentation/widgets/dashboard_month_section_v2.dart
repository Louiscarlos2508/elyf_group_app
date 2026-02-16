import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

import 'immobilier_kpi_card.dart';

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
    this.totalDepositsHeld = 0,
    this.totalArrears = 0,
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
  final int totalDepositsHeld;
  final int totalArrears;
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
          ImmobilierKpiCard(
            label: 'Revenus Locatifs',
            value: CurrencyFormatter.formatFCFA(monthRevenue),
            subtitle: '$monthPaymentsCount paiements (${collectionRate.toStringAsFixed(0)}%)',
            icon: Icons.trending_up,
            color: const Color(0xFF3B82F6),
            onTap: onRevenueTap,
          ),
          ImmobilierKpiCard(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(monthExpensesAmount),
            subtitle: 'Charges',
            icon: Icons.receipt_long,
            color: theme.colorScheme.error,
            onTap: onExpensesTap,
          ),
          ImmobilierKpiCard(
            label: 'Loyers Impayés',
            value: '$unpaidRentsCount',
            subtitle: 'Contrats en attente',
            icon: Icons.money_off,
            color: unpaidRentsCount > 0 ? theme.colorScheme.error : const Color(0xFF10B981),
            onTap: null,
          ),
          ImmobilierKpiCard(
            label: 'Bénéfice Net',
            value: CurrencyFormatter.formatFCFA(monthProfit),
            subtitle: monthProfit >= 0 ? 'Profit' : 'Déficit',
            icon: Icons.account_balance_wallet,
            color: monthProfit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
            onTap: onProfitTap,
          ),
          ImmobilierKpiCard(
            label: "Taux d'Occupation",
            value: '${occupancyRate.toStringAsFixed(0)}%',
            subtitle: 'propriétés louées',
            icon: Icons.home,
            color: const Color(0xFF6366F1),
            onTap: onOccupancyTap,
          ),
          if (openTickets > 0 || onMaintenanceTap != null)
            ImmobilierKpiCard(
              label: 'Maintenance',
              value: '$openTickets tickets',
              subtitle: '$highPriorityTickets urgents',
              icon: Icons.handyman,
              color: highPriorityTickets > 0 ? Colors.red : Colors.orange,
              onTap: onMaintenanceTap,
            ),
          ImmobilierKpiCard(
            label: 'Cautions Détenues',
            value: CurrencyFormatter.formatFCFA(totalDepositsHeld),
            subtitle: 'Dépôts de garantie',
            icon: Icons.lock_clock,
            color: const Color(0xFF8B5CF6),
            onTap: null,
          ),
          ImmobilierKpiCard(
            label: 'Total Arriérés',
            value: CurrencyFormatter.formatFCFA(totalArrears),
            subtitle: 'Dettes cumulées',
            icon: Icons.warning_amber_rounded,
            color: totalArrears > 0 ? theme.colorScheme.error : const Color(0xFF10B981),
            onTap: null,
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
                ],
                if (cards.length > 5) ...[
                   const SizedBox(width: 16),
                   Expanded(child: cards[5]),
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

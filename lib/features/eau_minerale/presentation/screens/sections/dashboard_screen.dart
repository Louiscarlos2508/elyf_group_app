import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/dashboard_month_kpis.dart';
import '../../widgets/dashboard_stock_list.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/dashboard_trends_chart.dart';
import '../../widgets/stock_alert_banner.dart';

/// Professional dashboard screen with organized sections and responsive layout.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return CustomScrollView(
          slivers: [
            // Header with Premium Gradient
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF00C2FF), // Cyan for Water Module
                      const Color(0xFF0369A1), // Deep Blue
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "EAU MINÉRALE",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tableau de Bord",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RefreshButton(
                      // color: Colors.white,
                      onRefresh: () async {
                        ref.invalidate(salesStateProvider);
                        ref.invalidate(financesStateProvider);
                        ref.invalidate(clientsStateProvider);
                        ref.invalidate(stockStateProvider);
                        ref.invalidate(productionSessionsStateProvider);
                      },
                      tooltip: 'Actualiser',
                    ),
                  ],
                ),
              ),
            ),

            // Stock alerts
            const SliverToBoxAdapter(
              child: DashboardStockAlerts(),
            ),

            // Today section
            const SectionHeader(
              title: "AUJOURD'HUI",
              top: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            const SliverPadding(
              padding: AppSpacing.sectionPadding,
              sliver: SliverToBoxAdapter(
                child: DashboardTodaySection(),
              ),
            ),

            // Month KPIs section
            const SectionHeader(
              title: 'CE MOIS',
              bottom: AppSpacing.sm,
            ),
            const SliverPadding(
              padding: AppSpacing.sectionPadding,
              sliver: SliverToBoxAdapter(
                child: DashboardMonthKpis(),
              ),
            ),

            // Trends chart section
            const SectionHeader(
              title: 'TENDANCES',
              bottom: AppSpacing.sm,
            ),
            const SliverPadding(
              padding: AppSpacing.sectionPadding,
              sliver: SliverToBoxAdapter(
                child: DashboardTrendsChart(),
              ),
            ),

            // Stock section
            const SectionHeader(
              title: 'Stock Produits Finis',
              bottom: AppSpacing.sm,
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: DashboardStockList(),
              ),
            ),
          ],
    );
  }
}

/// Extracted widget for stock alerts to minimize DashboardScreen rebuilds.
class DashboardStockAlerts extends ConsumerWidget {
  const DashboardStockAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockState = ref.watch(stockStateProvider);
    return stockState.when(
      data: (data) {
        final lowStockItems = data.items
            .where(
              (item) =>
                  item.type == StockType.finishedGoods &&
                  item.quantity < 100,
            )
            .toList();
        if (lowStockItems.isEmpty) return const SizedBox.shrink();
        return StockAlertBanner(
          productName: lowStockItems.first.name,
          onTap: () {
            // Navigate to stock screen
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

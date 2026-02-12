import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
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
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;

    return CustomScrollView(
          slivers: [
            // Header with Premium Gradient
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F4C75), // Deep Water Blue
                      Color(0xFF3282B8), // Mid Water Blue
                      Color(0xFF00C2FF), // Vibrant Cyan
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4C75).withValues(alpha: 0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              activeEnterprise?.name.toUpperCase() ?? "EAU MINÉRALE",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Tableau de Bord",
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              fontSize: 36,
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
            const SliverSectionHeader(
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
            const SliverSectionHeader(
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
            const SliverSectionHeader(
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
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
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

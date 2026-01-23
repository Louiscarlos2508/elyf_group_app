import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_month_kpis.dart';
import '../../widgets/dashboard_stock_list.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/dashboard_trends_chart.dart';
import '../../widgets/stock_alert_banner.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';

/// Professional dashboard screen with organized sections and responsive layout.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesStateProvider);
    final stockState = ref.watch(stockStateProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    isWide ? AppSpacing.lg : AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DashboardHeader(
                          date: DateTime.now(),
                          role: 'Responsable',
                        ),
                      ),
                      Semantics(
                        label: 'Actualiser le tableau de bord',
                        hint: 'Recharge toutes les données affichées',
                        button: true,
                        child: RefreshButton(
                          onRefresh: () {
                            ref.invalidate(salesStateProvider);
                            ref.invalidate(financesStateProvider);
                            ref.invalidate(clientsStateProvider);
                            ref.invalidate(stockStateProvider);
                            ref.invalidate(productionSessionsStateProvider);
                          },
                          tooltip: 'Actualiser le tableau de bord',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Stock alerts
          SliverToBoxAdapter(
            child: stockState.when(
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
            ),
          ),

          // Today section
          SectionHeader(
            title: "AUJOURD'HUI",
            top: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: SliverToBoxAdapter(
              child: salesState.when(
                data: (data) => DashboardTodaySection(salesState: data),
                loading: () => const LoadingIndicator(),
                error: (error, stackTrace) => ErrorDisplayWidget(
                  error: error,
                  onRetry: () => ref.refresh(salesStateProvider),
                ),
              ),
            ),
          ),

          // Month KPIs section
          const SectionHeader(
            title: 'CE MOIS',
            bottom: AppSpacing.sm,
          ),
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: const SliverToBoxAdapter(
              child: DashboardMonthKpis(),
            ),
          ),

          // Trends chart section
          const SectionHeader(
            title: 'TENDANCES',
            bottom: AppSpacing.sm,
          ),
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: const SliverToBoxAdapter(
              child: DashboardTrendsChart(),
            ),
          ),

          // Stock section
          const SectionHeader(
            title: 'Stock Produits Finis',
            bottom: AppSpacing.sm,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: stockState.when(
                data: (data) => DashboardStockList(stockState: data),
                loading: () => const LoadingIndicator(height: 100),
                error: (error, stackTrace) => ErrorDisplayWidget(
                  error: error,
                  title: 'Stock indisponible',
                  message: 'Impossible de charger le stock.',
                  onRetry: () => ref.refresh(stockStateProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

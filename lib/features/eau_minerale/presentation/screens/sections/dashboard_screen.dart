import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/refresh_button.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_month_kpis.dart';
import '../../widgets/dashboard_stock_list.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/dashboard_trends_chart.dart';
import '../../widgets/section_placeholder.dart';
import '../../widgets/stock_alert_banner.dart';

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
                    24,
                    24,
                    24,
                    isWide ? 24 : 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            DashboardHeader(date: DateTime.now(), role: 'Responsable'),
                      ),
                      RefreshButton(
                        onRefresh: () {
                          ref.invalidate(salesStateProvider);
                          ref.invalidate(financesStateProvider);
                          ref.invalidate(clientsStateProvider);
                          ref.invalidate(stockStateProvider);
                          ref.invalidate(productionSessionsStateProvider);
                        },
                        tooltip: 'Actualiser le tableau de bord',
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
          _buildSectionHeader("AUJOURD'HUI", 24, 16),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: salesState.when(
                data: (data) => DashboardTodaySection(salesState: data),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Month KPIs section
          _buildSectionHeader('CE MOIS', 0, 8),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: DashboardMonthKpis(),
            ),
          ),

          // Trends chart section
          _buildSectionHeader('TENDANCES', 0, 8),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: DashboardTrendsChart(),
            ),
          ),

          // Stock section
          _buildSectionHeader('Stock Produits Finis', 0, 8),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverToBoxAdapter(
              child: stockState.when(
                data: (data) => DashboardStockList(stockState: data),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => SectionPlaceholder(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock indisponible',
                  subtitle: 'Impossible de charger le stock.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double top, double bottom) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

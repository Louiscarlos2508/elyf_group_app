import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_month_section.dart';
import '../../widgets/dashboard_operations_section.dart';
import '../../widgets/dashboard_stock_list.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/section_placeholder.dart';
import '../../widgets/stock_alert_banner.dart';

/// Professional dashboard screen with organized sections and responsive layout.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesStateProvider);
    // TODO: Réimplémenter avec productionSessionsStateProvider
    // final productionState = ref.watch(productionStateProvider);
    final financesState = ref.watch(financesStateProvider);
    final clientsState = ref.watch(clientsStateProvider);
    final stockState = ref.watch(stockStateProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(date: DateTime.now(), role: 'Responsable'),
          ),
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
          // TODO: Réimplémenter les sections de production avec les sessions
          // _buildSectionHeader('CE MOIS', 0, 8),
          // SliverPadding(
          //   padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          //   sliver: SliverToBoxAdapter(
          //     child: DashboardMonthSection(
          //       salesState: salesState,
          //       productionState: productionState,
          //       clientsState: clientsState,
          //       financesState: financesState,
          //     ),
          //   ),
          // ),
          // _buildSectionHeader('Opérations', 0, 8),
          // SliverPadding(
          //   padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          //   sliver: SliverToBoxAdapter(
          //     child: DashboardOperationsSection(
          //       productionState: productionState,
          //       financesState: financesState,
          //     ),
          //   ),
          // ),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

}

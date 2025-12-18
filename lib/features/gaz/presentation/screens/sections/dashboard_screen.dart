import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/refresh_button.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_month_section.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/stock_summary_card.dart';

/// Professional dashboard screen for gaz module.
class GazDashboardScreen extends ConsumerWidget {
  const GazDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(gasSalesProvider);
    final expensesAsync = ref.watch(gazExpensesProvider);
    final cylindersAsync = ref.watch(cylindersProvider);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: GazDashboardHeader(
                    date: DateTime.now(),
                    role: 'Gérant',
                  ),
                ),
                RefreshButton(
                  onRefresh: () {
                    ref.invalidate(gasSalesProvider);
                    ref.invalidate(cylindersProvider);
                    ref.invalidate(gazExpensesProvider);
                  },
                  tooltip: 'Actualiser le tableau de bord',
                ),
              ],
            ),
          ),
        ),

        // Today section header
        _buildSectionHeader("AUJOURD'HUI", 8, 8),

        // Today KPIs
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverToBoxAdapter(
            child: salesAsync.when(
              data: (sales) {
                final today = DateTime.now();
                final todaySales = sales
                    .where((s) =>
                        s.saleDate.year == today.year &&
                        s.saleDate.month == today.month &&
                        s.saleDate.day == today.day)
                    .toList();
                return GazDashboardTodaySection(todaySales: todaySales);
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Month section header
        _buildSectionHeader('CE MOIS', 0, 8),

        // Month KPIs
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverToBoxAdapter(
            child: _buildMonthKpis(
              salesAsync,
              expensesAsync,
            ),
          ),
        ),

        // Stock section header
        _buildSectionHeader('STOCK', 0, 8),

        // Stock summary
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          sliver: SliverToBoxAdapter(
            child: cylindersAsync.when(
              data: (cylinders) => StockSummaryCard(cylinders: cylinders),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, double top, double bottom) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthKpis(
    AsyncValue<List<GasSale>> salesAsync,
    AsyncValue<List<GazExpense>> expensesAsync,
  ) {
    return salesAsync.when(
      data: (sales) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        final monthSales = sales
            .where((s) => s.saleDate.isAfter(monthStart.subtract(
                  const Duration(days: 1),
                )))
            .toList();
        final monthRevenue = monthSales.fold<double>(
          0,
          (sum, s) => sum + s.totalAmount,
        );

        return expensesAsync.when(
          data: (expenses) {
            final monthExpenses = expenses
                .where((e) => e.date.isAfter(monthStart.subtract(
                      const Duration(days: 1),
                    )))
                .toList();
            final monthExpensesAmount = monthExpenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );

            final monthProfit = monthRevenue - monthExpensesAmount;

            return GazDashboardMonthSection(
              monthRevenue: monthRevenue,
              monthSalesCount: monthSales.length,
              monthExpensesAmount: monthExpensesAmount,
              monthProfit: monthProfit,
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

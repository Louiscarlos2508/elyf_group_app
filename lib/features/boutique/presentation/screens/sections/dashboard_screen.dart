import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_low_stock_list.dart';
import '../../widgets/dashboard_month_section.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/restock_dialog.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';

/// Professional dashboard screen for boutique module.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final purchasesAsync = ref.watch(purchasesProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      body: CustomScrollView(
      slivers: [
          // Header
        SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                  Expanded(
                    child: DashboardHeader(
                      date: DateTime.now(),
                      role: 'Gérant',
                ),
                  ),
                  RefreshButton(
                    onRefresh: () {
                      ref.invalidate(recentSalesProvider);
                      ref.invalidate(productsProvider);
                      ref.invalidate(lowStockProductsProvider);
                      ref.invalidate(purchasesProvider);
                      ref.invalidate(expensesProvider);
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
                  final calculationService = ref.read(
                    boutiqueDashboardCalculationServiceProvider,
                  );
                  final metrics = calculationService.calculateTodayMetrics(
                    sales,
                  );
                  return DashboardTodaySection(metrics: metrics);
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
                ref,
                salesAsync,
                purchasesAsync,
                expensesAsync,
              ),
            ),
          ),

          // Low stock section header
          _buildSectionHeader('ALERTES STOCK', 0, 8),

          // Low stock list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverToBoxAdapter(
              child: lowStockAsync.when(
                data: (products) => DashboardLowStockList(
                  products: products,
                  onProductTap: (product) {
                    showDialog(
                      context: context,
                      builder: (_) => RestockDialog(product: product),
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthKpis(
    WidgetRef ref,
    AsyncValue<List<Sale>> salesAsync,
    AsyncValue<List<Purchase>> purchasesAsync,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    return salesAsync.when(
      data: (sales) => purchasesAsync.when(
        data: (purchases) => expensesAsync.when(
          data: (expenses) {
            final calculationService = ref.read(
              boutiqueDashboardCalculationServiceProvider,
            );

            // Use the calculation service for monthly metrics
            final metrics = calculationService.calculateMonthlyMetricsWithPurchases(
              sales: sales,
              expenses: expenses,
              purchases: purchases,
            );

            return DashboardMonthSection(
              monthRevenue: metrics.revenue,
              monthSalesCount: metrics.salesCount,
              monthPurchasesAmount: metrics.purchasesAmount,
              monthExpensesAmount: metrics.expensesAmount,
              monthProfit: metrics.profit,
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

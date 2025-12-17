import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/refresh_button.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/sale.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_low_stock_list.dart';
import '../../widgets/dashboard_month_section.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/restock_dialog.dart';

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
                      final today = DateTime.now();
                  final todaySales = sales
                      .where((s) =>
                          s.date.year == today.year &&
                          s.date.month == today.month &&
                          s.date.day == today.day)
                      .toList();
                  return DashboardTodaySection(todaySales: todaySales);
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
    AsyncValue<List<Sale>> salesAsync,
    AsyncValue purchasesAsync,
    AsyncValue expensesAsync,
  ) {
    return salesAsync.when(
      data: (sales) {
                    final now = DateTime.now();
                    final monthStart = DateTime(now.year, now.month, 1);
                    
        final monthSales = sales
            .where((s) => s.date.isAfter(monthStart.subtract(
                  const Duration(days: 1),
                )))
            .toList();
        final monthRevenue =
            monthSales.fold(0, (sum, s) => sum + s.totalAmount);
                    
                    return purchasesAsync.when(
                      data: (purchases) {
            final monthPurchases = (purchases as List)
                .where((p) => p.date.isAfter(monthStart.subtract(
                      const Duration(days: 1),
                    )))
                .toList();
            final monthPurchasesAmount = monthPurchases.fold<int>(
              0,
              (sum, p) => sum + (p.totalAmount as int),
            );

                        return expensesAsync.when(
                          data: (expenses) {
                final monthExpenses = (expenses as List)
                    .where((e) => e.date.isAfter(monthStart.subtract(
                          const Duration(days: 1),
                        )))
                    .toList();
                final monthExpensesAmount = monthExpenses.fold<int>(
                  0,
                  (sum, e) => sum + (e.amountCfa as int),
                );
                            
                final monthProfit =
                    monthRevenue - monthPurchasesAmount - monthExpensesAmount;

                return DashboardMonthSection(
                      monthRevenue: monthRevenue,
                      monthSalesCount: monthSales.length,
                      monthPurchasesAmount: monthPurchasesAmount,
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
                  },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
                  error: (_, __) => const SizedBox.shrink(),
                );
  }
}

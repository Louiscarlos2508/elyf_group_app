import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../widgets/dashboard_kpi_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(recentSalesProvider);
    final productsAsync = ref.watch(productsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final purchasesAsync = ref.watch(purchasesProvider);
    final expensesAsync = ref.watch(expensesProvider);

    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Text(
                  'Tableau de Bord',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 20 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return salesAsync.when(
                  data: (sales) {
                    final todaySales = sales.where((sale) {
                      final today = DateTime.now();
                      return sale.date.year == today.year &&
                          sale.date.month == today.month &&
                          sale.date.day == today.day;
                    }).toList();

                    final todayRevenue = todaySales.fold(
                      0,
                      (sum, sale) => sum + sale.totalAmount,
                    );
                    final todayCount = todaySales.length;
                    
                    // Calculate week and month stats
                    final now = DateTime.now();
                    final weekStart = now.subtract(Duration(days: now.weekday - 1));
                    final monthStart = DateTime(now.year, now.month, 1);
                    
                    final weekSales = sales.where((sale) {
                      return sale.date.isAfter(weekStart.subtract(const Duration(days: 1)));
                    }).toList();
                    final weekRevenue = weekSales.fold(0, (sum, sale) => sum + sale.totalAmount);
                    
                    final monthSales = sales.where((sale) {
                      return sale.date.isAfter(monthStart.subtract(const Duration(days: 1)));
                    }).toList();
                    final monthRevenue = monthSales.fold(0, (sum, sale) => sum + sale.totalAmount);
                    
                    // Calculate purchases and expenses for the month
                    return purchasesAsync.when(
                      data: (purchases) {
                        return expensesAsync.when(
                          data: (expenses) {
                            final monthPurchases = purchases.where((p) {
                              return p.date.isAfter(monthStart.subtract(const Duration(days: 1)));
                            }).toList();
                            final monthPurchasesAmount = monthPurchases.fold(0, (sum, p) => sum + p.totalAmount);
                            
                            final monthExpenses = expenses.where((e) {
                              return e.date.isAfter(monthStart.subtract(const Duration(days: 1)));
                            }).toList();
                            final monthExpensesAmount = monthExpenses.fold(0, (sum, e) => sum + e.amountCfa);
                            
                            final monthProfit = monthRevenue - monthPurchasesAmount - monthExpensesAmount;

                    return DashboardKpiGrid(
                      todayCount: todayCount,
                      todayRevenue: todayRevenue,
                      weekRevenue: weekRevenue,
                      weekSalesCount: weekSales.length,
                      monthRevenue: monthRevenue,
                      monthSalesCount: monthSales.length,
                      monthPurchasesAmount: monthPurchasesAmount,
                      monthPurchasesCount: monthPurchases.length,
                      monthExpensesAmount: monthExpensesAmount,
                      monthExpensesCount: monthExpenses.length,
                      monthProfit: monthProfit,
                    );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}


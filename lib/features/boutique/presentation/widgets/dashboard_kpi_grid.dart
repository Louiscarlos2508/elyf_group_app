import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import 'dashboard_kpi_card.dart';

class DashboardKpiGrid extends ConsumerWidget {
  const DashboardKpiGrid({
    super.key,
    required this.todayCount,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.weekSalesCount,
    required this.monthRevenue,
    required this.monthSalesCount,
    required this.monthPurchasesAmount,
    required this.monthPurchasesCount,
    required this.monthExpensesAmount,
    required this.monthExpensesCount,
    required this.monthProfit,
  });

  final int todayCount;
  final int todayRevenue;
  final int weekRevenue;
  final int weekSalesCount;
  final int monthRevenue;
  final int monthSalesCount;
  final int monthPurchasesAmount;
  final int monthPurchasesCount;
  final int monthExpensesAmount;
  final int monthExpensesCount;
  final int monthProfit;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final isMedium = constraints.maxWidth > 600;
        // Sur mobile, utiliser 2 colonnes pour mieux utiliser l'espace
        final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 2);
        // Aspect ratio plus compact sur mobile
        final childAspectRatio = isWide ? 1.2 : (isMedium ? 1.3 : 1.4);
        
        return productsAsync.when(
          data: (products) {
            return lowStockAsync.when(
              data: (lowStockProducts) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isWide ? 16 : 12,
                  mainAxisSpacing: isWide ? 16 : 12,
                  padding: EdgeInsets.all(isWide ? 0 : 12),
                  childAspectRatio: childAspectRatio,
                  children: [
                    DashboardKpiCard(
                      label: 'Ventes Aujourd\'hui',
                      value: '$todayCount',
                      subtitle: _formatCurrency(todayRevenue),
                      icon: Icons.shopping_cart,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue,
                    ),
                    DashboardKpiCard(
                      label: 'Produits',
                      value: '${products.length}',
                      subtitle: 'En catalogue',
                      icon: Icons.inventory_2,
                      iconColor: Colors.green,
                      backgroundColor: Colors.green,
                    ),
                    DashboardKpiCard(
                      label: 'Stock Faible',
                      value: '${lowStockProducts.length}',
                      subtitle: 'À réapprovisionner',
                      icon: Icons.warning,
                      iconColor: Colors.orange,
                      backgroundColor: Colors.orange,
                    ),
                    DashboardKpiCard(
                      label: 'Semaine',
                      value: _formatCurrency(weekRevenue),
                      subtitle: '${weekSalesCount} ventes',
                      icon: Icons.calendar_view_week,
                      iconColor: Colors.purple,
                      backgroundColor: Colors.purple,
                    ),
                    DashboardKpiCard(
                      label: 'Mois',
                      value: _formatCurrency(monthRevenue),
                      subtitle: '${monthSalesCount} ventes',
                      icon: Icons.calendar_month,
                      iconColor: Colors.indigo,
                      backgroundColor: Colors.indigo,
                    ),
                    DashboardKpiCard(
                      label: 'Achats (Mois)',
                      value: _formatCurrency(monthPurchasesAmount),
                      subtitle: '${monthPurchasesCount} achats',
                      icon: Icons.shopping_bag,
                      iconColor: Colors.cyan,
                      backgroundColor: Colors.cyan,
                    ),
                    DashboardKpiCard(
                      label: 'Dépenses (Mois)',
                      value: _formatCurrency(monthExpensesAmount),
                      subtitle: '${monthExpensesCount} dépenses',
                      icon: Icons.receipt_long,
                      iconColor: Colors.deepOrange,
                      backgroundColor: Colors.deepOrange,
                    ),
                    DashboardKpiCard(
                      label: 'Bénéfice (Mois)',
                      value: _formatCurrency(monthProfit),
                      subtitle: monthRevenue > 0 
                          ? '${((monthProfit / monthRevenue) * 100).toStringAsFixed(1)}% marge'
                          : 'N/A',
                      icon: Icons.account_balance_wallet,
                      iconColor: monthProfit >= 0 ? Colors.purple : Colors.red,
                      backgroundColor: monthProfit >= 0 ? Colors.purple : Colors.red,
                    ),
                  ],
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
    );
  }
}


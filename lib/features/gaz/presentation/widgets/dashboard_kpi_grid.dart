import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/gas_sale.dart';
import 'enhanced_kpi_card.dart';

/// Widget pour afficher la grille de KPIs du dashboard Gaz.
class GazDashboardKpiGrid extends ConsumerWidget {
  const GazDashboardKpiGrid({
    super.key,
    required this.cylinders,
    required this.sales,
    required this.expenses,
  });

  final List<Cylinder> cylinders;
  final List<GasSale> sales;
  final List<GazExpense> expenses;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Récupérer le stock total (pleines) depuis CylinderStock
    String? enterpriseId = cylinders.isNotEmpty
        ? cylinders.first.enterpriseId
        : 'default_enterprise';
    
    final stocksAsync = ref.watch(
      cylinderStocksProvider(
        (
          enterpriseId: enterpriseId,
          status: CylinderStatus.full,
          siteId: null,
        ),
      ),
    );

    return stocksAsync.when(
      data: (stocks) {
        // Calculer le stock total (pleines)
        final totalStock = stocks.fold<int>(0, (sum, s) => sum + s.quantity);

        // Ventes du jour
        final todaySales = sales.where((s) {
          final saleDate = DateTime(
            s.saleDate.year,
            s.saleDate.month,
            s.saleDate.day,
          );
          return saleDate.isAtSameMomentAs(today);
        }).toList();
        final todayRevenue =
            todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);

        // Ventes de la semaine
        final weekSales = sales.where((s) {
          return s.saleDate
              .isAfter(weekStart.subtract(const Duration(days: 1)));
        }).toList();
        final weekRevenue =
            weekSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

        // Ventes du mois
        final monthSales = sales.where((s) {
          return s.saleDate
              .isAfter(monthStart.subtract(const Duration(days: 1)));
        }).toList();
        final monthRevenue =
            monthSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

        // Dépenses du mois
        final monthExpenses = expenses.where((e) {
          return e.date.isAfter(monthStart.subtract(const Duration(days: 1)));
        }).toList();
        final monthExpensesTotal =
            monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

        // Bénéfice du mois
        final monthProfit = monthRevenue - monthExpensesTotal;

        // Ventes détail vs gros
        final retailSales = monthSales
            .where((s) => s.saleType == SaleType.retail)
            .length;
        final wholesaleSales = monthSales
            .where((s) => s.saleType == SaleType.wholesale)
            .length;

        final cards = [
          GazEnhancedKpiCard(
            label: 'Stock total',
            value: '$totalStock',
            subtitle: '${cylinders.length} types',
            icon: Icons.inventory_2,
            color: Colors.blue,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes du jour',
            value: CurrencyFormatter.formatDouble(todayRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '${todaySales.length} ventes',
            icon: Icons.today,
            color: Colors.green,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes semaine',
            value: CurrencyFormatter.formatDouble(weekRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '${weekSales.length} ventes',
            icon: Icons.date_range,
            color: Colors.teal,
          ),
          GazEnhancedKpiCard(
            label: 'Revenus du mois',
            value: CurrencyFormatter.formatDouble(monthRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '${monthSales.length} ventes',
            icon: Icons.trending_up,
            color: Colors.indigo,
          ),
          GazEnhancedKpiCard(
            label: 'Dépenses du mois',
            value: CurrencyFormatter.formatDouble(monthExpensesTotal).replaceAll(' FCFA', ' F'),
            subtitle: '${monthExpenses.length} dépenses',
            icon: Icons.trending_down,
            color: Colors.red,
          ),
          GazEnhancedKpiCard(
            label: 'Bénéfice net',
            value: CurrencyFormatter.formatDouble(monthProfit).replaceAll(' FCFA', ' F'),
            icon: Icons.account_balance_wallet,
            color: monthProfit >= 0 ? Colors.green : Colors.red,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes détail',
            value: '$retailSales',
            icon: Icons.store,
            color: Colors.orange,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes gros',
            value: '$wholesaleSales',
            icon: Icons.local_shipping,
            color: Colors.purple,
          ),
        ];

        return Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isWide = screenWidth > 600;

            if (isWide) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[2]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[3]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[4]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[5]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[6]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[7]),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < cards.length; i += 2) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[i]),
                      const SizedBox(width: 12),
                      if (i + 1 < cards.length)
                        Expanded(child: cards[i + 1]),
                      if (i + 1 >= cards.length)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  if (i + 2 < cards.length) const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
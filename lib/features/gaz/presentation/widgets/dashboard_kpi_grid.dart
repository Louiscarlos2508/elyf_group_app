import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
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
        // Utiliser le service de calcul pour extraire la logique métier
        final calculationService = ref.read(gazDashboardCalculationServiceProvider);
        final metrics = calculationService.calculateMetrics(
          stocks: stocks,
          sales: sales,
          expenses: expenses,
          cylinderTypesCount: cylinders.length,
        );

        final cards = [
          GazEnhancedKpiCard(
            label: 'Stock total',
            value: '${metrics.totalStock}',
            subtitle: '${metrics.cylinderTypesCount} types',
            icon: Icons.inventory_2,
            color: Colors.blue,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes du jour',
            value: CurrencyFormatter.formatDouble(metrics.todayRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '${metrics.todaySalesCount} ventes',
            icon: Icons.today,
            color: Colors.green,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes semaine',
            value: CurrencyFormatter.formatDouble(metrics.weekRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '${metrics.weekSalesCount} ventes',
            icon: Icons.date_range,
            color: Colors.teal,
          ),
          GazEnhancedKpiCard(
            label: 'Revenus du mois',
            value: CurrencyFormatter.formatDouble(metrics.monthRevenue).replaceAll(' FCFA', ' F'),
            subtitle: '${metrics.monthSalesCount} ventes',
            icon: Icons.trending_up,
            color: Colors.indigo,
          ),
          GazEnhancedKpiCard(
            label: 'Dépenses du mois',
            value: CurrencyFormatter.formatDouble(metrics.monthExpensesTotal).replaceAll(' FCFA', ' F'),
            subtitle: '${metrics.monthExpensesCount} dépenses',
            icon: Icons.trending_down,
            color: Colors.red,
          ),
          GazEnhancedKpiCard(
            label: 'Bénéfice net',
            value: CurrencyFormatter.formatDouble(metrics.monthProfit).replaceAll(' FCFA', ' F'),
            icon: Icons.account_balance_wallet,
            color: metrics.isProfit ? Colors.green : Colors.red,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes détail',
            value: '${metrics.retailSalesCount}',
            icon: Icons.store,
            color: Colors.orange,
          ),
          GazEnhancedKpiCard(
            label: 'Ventes gros',
            value: '${metrics.wholesaleSalesCount}',
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
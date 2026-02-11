import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';

/// Section des KPI cards pour le dashboard.
class DashboardKpiSection extends ConsumerWidget {
  const DashboardKpiSection({
    super.key,
    required this.sales,
    required this.expenses,
    required this.cylinders,
  });

  final List<GasSale> sales;
  final List<GazExpense> expenses;
  final List<Cylinder> cylinders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser le service pour les calculs
    final todaySales = GazCalculationService.calculateTodaySales(sales);
    final todayRevenue = GazCalculationService.calculateTodayRevenue(sales);
    final todayExpenses = GazCalculationService.calculateTodayExpenses(
      expenses,
    );
    final todayExpensesAmount =
        GazCalculationService.calculateTodayExpensesTotal(expenses);
    final todayProfit = GazCalculationService.calculateTodayProfit(
      sales,
      expenses,
    );

    // Full bottles count
    final enterpriseId = cylinders.isNotEmpty
        ? cylinders.first.enterpriseId
        : 'default_enterprise';

    // Récupérer tous les stocks pour calculer pleines et vides
    final allStocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: enterpriseId,
        status: null, // null = tous les stocks
        siteId: null,
      )),
    );

    return allStocksAsync.when(
      data: (allStocks) {
        // Calculer les bouteilles pleines
        final fullBottles = GazCalculationService.calculateTotalFullCylinders(
          allStocks,
        );
        // Calculer les bouteilles vides (emptyAtStore + emptyInTransit)
        final emptyBottles = GazCalculationService.calculateTotalEmptyCylinders(
          allStocks,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Ventes du jour",
                      value: CurrencyFormatter.formatDouble(todayRevenue),
                      subtitle: "${todaySales.length} vente(s)",
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF3B82F6), // Vibrant Blue
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Dépenses du jour",
                      value: CurrencyFormatter.formatDouble(todayExpensesAmount),
                      subtitle: "${todayExpenses.length} dépense(s)",
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFEF4444), // Vibrant Red
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Bénéfice du jour",
                      value: CurrencyFormatter.formatDouble(todayProfit),
                      subtitle: todayProfit >= 0 ? "Bénéfice net" : "Déficit journalier",
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF10B981), // Emerald Green
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Bouteilles pleines",
                      value: "$fullBottles",
                      subtitle: "$emptyBottles vides",
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF8B5CF6), // Vibrant Violet
                    ),
                  ),
                ],
              );
            }

            // Mobile layout: 2x2 grid
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElyfStatsCard(
                        label: "Ventes du jour",
                        value: CurrencyFormatter.formatDouble(todayRevenue),
                        subtitle: "${todaySales.length} vente(s)",
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElyfStatsCard(
                        label: "Dépenses du jour",
                        value: CurrencyFormatter.formatDouble(todayExpensesAmount),
                        subtitle: "${todayExpenses.length} dépense(s)",
                        icon: Icons.trending_down_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElyfStatsCard(
                        label: "Bénéfice du jour",
                        value: CurrencyFormatter.formatDouble(todayProfit),
                        subtitle: todayProfit >= 0 ? "Bénéfice net" : "Déficit journalier",
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElyfStatsCard(
                        label: "Bouteilles pleines",
                        value: "$fullBottles",
                        subtitle: "$emptyBottles vides",
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
      loading: () => Column(
        children: [
          ElyfShimmer(child: ElyfShimmer.listTile()),
          const SizedBox(height: 12),
          ElyfShimmer(child: ElyfShimmer.listTile()),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

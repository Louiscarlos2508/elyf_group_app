import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/entities/gaz_settings.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../../application/providers.dart';

/// Section des KPI cards pour le dashboard.
class DashboardKpiSection extends ConsumerWidget {
  const DashboardKpiSection({
    super.key,
    required this.sales,
    required this.expenses,
    required this.cylinders,
    required this.stocks,
    this.settings,
    this.viewType = GazDashboardViewType.consolidated,
  });

  final List<GasSale> sales;
  final List<GazExpense> expenses;
  final List<Cylinder> cylinders;
  final List<CylinderStock> stocks;
  final GazSettings? settings;
  final GazDashboardViewType viewType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
      cylinders,
    );

    // Calculer les bouteilles pleines
    final fullBottles = GazCalculationService.calculateTotalFullCylinders(
      stocks,
    );
    
    // Calculer les bouteilles vides
    int emptyBottles = 0;
    final s = settings;
    if (viewType == GazDashboardViewType.local && s != null) {
      // En vue locale, le vide = Nominal - Plein
      for (final weight in s.nominalStocks.keys) {
        final nominal = s.getNominalStock(weight);
        final fullForWeight = stocks
            .where((s) => s.weight == weight && s.status == CylinderStatus.full)
            .fold<int>(0, (sum, s) => sum + s.quantity);
        emptyBottles += (nominal - fullForWeight).clamp(0, nominal).toInt();
      }
    } else {
      // En vue consolidée, c'est le cumul du stock physique vide
      emptyBottles = GazCalculationService.calculateTotalEmptyCylinders(
        stocks,
      );
    }

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
                      color: theme.colorScheme.primary, // Vibrant Blue
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Dépenses du jour",
                      value: CurrencyFormatter.formatDouble(todayExpensesAmount),
                      subtitle: "${todayExpenses.length} dépense(s)",
                      icon: Icons.trending_down_rounded,
                      color: theme.colorScheme.error, // Vibrant Red
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Bénéfice du jour",
                      value: CurrencyFormatter.formatDouble(todayProfit),
                      subtitle: todayProfit >= 0 ? "Bénéfice net" : "Déficit journalier",
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.success, // Emerald Green
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Bouteilles pleines",
                      value: "$fullBottles",
                      subtitle: "$emptyBottles vides",
                      icon: Icons.inventory_2_rounded,
                      color: theme.colorScheme.tertiary, // Vibrant Violet/Tertiary
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
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElyfStatsCard(
                        label: "Dépenses du jour",
                        value: CurrencyFormatter.formatDouble(todayExpensesAmount),
                        subtitle: "${todayExpenses.length} dépense(s)",
                        icon: Icons.trending_down_rounded,
                        color: theme.colorScheme.error,
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
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElyfStatsCard(
                        label: "Bouteilles pleines",
                        value: "$fullBottles",
                        subtitle: "$emptyBottles vides",
                        icon: Icons.inventory_2_rounded,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/entities/gaz_settings.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../../../domain/entities/stock_transfer.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_financial_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_sales_calculation_service.dart';

/// Section des KPI cards pour le dashboard.
class DashboardKpiSection extends ConsumerWidget {
  const DashboardKpiSection({
    super.key,
    required this.sales,
    required this.expenses,
    required this.cylinders,
    required this.stocks,
    required this.transfers,
    required this.pointsOfSale,
    this.settings,
    this.viewType = GazDashboardViewType.consolidated,
  });

  final List<GasSale> sales;
  final List<GazExpense> expenses;
  final List<Cylinder> cylinders;
  final List<CylinderStock> stocks;
  final List<StockTransfer> transfers;
  final List<Enterprise> pointsOfSale;
  final GazSettings? settings;
  final GazDashboardViewType viewType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? 'default';
    final isPos = activeEnterprise?.isPointOfSale ?? false;

    // Use centralized calculation service
    final metrics = GazStockCalculationService.calculateStockMetrics(
      stocks: stocks,
      pointsOfSale: pointsOfSale,
      cylinders: cylinders,
      transfers: transfers,
      settings: isPos ? null : settings,
      targetEnterpriseId: enterpriseId,
    );

    final todaySales = GazSalesCalculationService.calculateTodaySales(sales);
    final todayRevenue = GazSalesCalculationService.calculateTodayRevenue(sales);
    final todayExpenses = GazFinancialCalculationService.calculateTodayExpenses(expenses);
    final todayExpensesAmount = GazFinancialCalculationService.calculateTodayExpensesTotal(expenses);
    final todayProfit = GazFinancialCalculationService.calculateTodayProfit(sales, expenses, cylinders);

    final fullBottles = metrics.totalFull;
    final emptyBottles = metrics.totalEmpty;
    final transitBottles = metrics.totalCentralized;

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
                      subtitle: "$emptyBottles vides${transitBottles > 0 ? ' • $transitBottles transit' : ''}",
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
                        subtitle: "$emptyBottles vides${transitBottles > 0 ? ' • $transitBottles transit' : ''}",
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

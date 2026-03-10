import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_settings.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/pos_remittance.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_sales_calculation_service.dart';

/// Section des KPI cards pour le dashboard.
class DashboardKpiSection extends ConsumerWidget {
  const DashboardKpiSection({
    super.key,
    required this.sales,
    required this.remittances,
    required this.expenses,
    required this.cylinders,
    required this.stocks,
    required this.pointsOfSale,
    this.settings,
    this.viewType = GazDashboardViewType.consolidated,
  });

  final List<GasSale> sales;
  final List<GazPOSRemittance> remittances;
  final List<GazExpense> expenses;
  final List<Cylinder> cylinders;
  final List<CylinderStock> stocks;
  final List<Enterprise> pointsOfSale;
  final GazSettings? settings;
  final GazDashboardViewType viewType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? 'default';
    final isPos = activeEnterprise?.isPointOfSale ?? false;

    // Common calculation for stock (needed for both)
    final metrics = GazStockCalculationService.calculateStockMetrics(
      stocks: stocks,
      pointsOfSale: pointsOfSale,
      cylinders: cylinders,
      settings: isPos ? null : settings,
      targetEnterpriseId: enterpriseId,
    );
    final fullBottles = metrics.totalFull;
    final emptyBottles = metrics.totalEmpty;
    final transitBottles = metrics.totalCentralized;

    if (isPos) {
      // POS-specific metrics (Daily)
      final todaySales = GazSalesCalculationService.calculateTodaySales(sales);
      final todayRevenue = GazSalesCalculationService.calculateTodayRevenue(sales);

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final cards = [
            Expanded(
              child: ElyfStatsCard(
                label: "Ventes du jour",
                value: CurrencyFormatter.formatDouble(todayRevenue),
                subtitle: "${todaySales.length} vente(s)",
                icon: Icons.trending_up_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElyfStatsCard(
                label: "Bouteilles pleines",
                value: "$fullBottles",
                subtitle: "$emptyBottles vides${transitBottles > 0 ? ' • $transitBottles transit' : ''}",
                icon: Icons.inventory_2_rounded,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ];

          if (isWide) return Row(children: cards);
          return Row(children: cards); 
        },
      );
    } else {
      // Parent enterprise metrics (Yearly/Tour-centric)
      final toursAsync = ref.watch(gazYearlyToursProvider);
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);

      // Annual income (Wholesaler Sales + POS Remittances)
      final annualSales = sales.where((s) => !s.saleDate.isBefore(yearStart)).toList();
      final annualSalesAmount = annualSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
      
      final annualRemittances = remittances.where((r) => !r.remittanceDate.isBefore(yearStart)).toList();
      final annualRemittancesAmount = annualRemittances.fold<double>(0, (sum, r) => sum + r.amount);
      
      final totalAnnualIncoming = annualSalesAmount + annualRemittancesAmount;

      // Annual expenses (manual/direct expenses)
      final annualExpenses = expenses.where((e) => !e.date.isBefore(yearStart)).toList();
      final annualExpensesAmount = annualExpenses.fold<double>(0, (sum, e) => sum + e.amount);

      return toursAsync.when(
        data: (tours) {
          final openToursCount = tours.where((t) => t.status == TourStatus.open).length;
          
          final annualTourExpenses = tours.fold<double>(0, (sum, t) => sum + t.totalExpenses);
          final annualBottlesReceived = tours
              .where((t) => t.status == TourStatus.closed)
              .fold<int>(0, (sum, t) => sum + t.totalBottlesReceived);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final cards = [
                _buildKpiCard(
                  label: "Entrées (Année)",
                  value: CurrencyFormatter.formatDouble(totalAnnualIncoming),
                  subtitle: "${annualSales.length} ventes • ${annualRemittances.length} versements",
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                  isWide: isWide,
                ),
                _buildSpacer(isWide),
                _buildKpiCard(
                  label: "Coût Tours (Année)",
                  value: CurrencyFormatter.formatDouble(annualTourExpenses),
                  subtitle: "Logistique consolidée",
                  icon: Icons.payments_outlined,
                  color: theme.colorScheme.error,
                  isWide: isWide,
                ),
                _buildSpacer(isWide),
                _buildKpiCard(
                  label: "Bouteilles (Année)",
                  value: "$annualBottlesReceived",
                  subtitle: "Rechargées chez fournisseur",
                  icon: Icons.autorenew_rounded,
                  color: theme.colorScheme.tertiary,
                  isWide: isWide,
                ),
                _buildSpacer(isWide),
                _buildKpiCard(
                  label: "Dépenses (Année)",
                  value: CurrencyFormatter.formatDouble(annualExpensesAmount),
                  subtitle: "Charges de structure",
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFF59E0B), // Warm yellow/orange for fixed costs
                  isWide: isWide,
                ),
              ];

              if (isWide) return Row(children: cards);
              
              // For column layout on small screens
              return Column(
                children: [
                  Row(children: [cards[0], cards[2]]),
                  const SizedBox(height: 12),
                  Row(children: [cards[4], cards[6]]),
                ],
              );
            },
          );
        },
        loading: () => AppShimmers.statsGrid(context),
        error: (_, __) => const SizedBox.shrink(),
      );
    }
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isWide,
  }) {
    return Expanded(
      child: ElyfStatsCard(
        label: label,
        value: value,
        subtitle: subtitle,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildSpacer(bool isWide) => isWide ? const SizedBox(width: 16) : const SizedBox(width: 12);
}

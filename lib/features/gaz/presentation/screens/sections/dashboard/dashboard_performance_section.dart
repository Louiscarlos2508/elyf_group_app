import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../widgets/dashboard_performance_chart.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_financial_calculation_service.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

/// Section du graphique de performance pour le dashboard.
class DashboardPerformanceSection extends ConsumerWidget {
  const DashboardPerformanceSection({
    super.key,
    required this.sales,
    required this.expenses,
  });

  final List<GasSale> sales;
  final List<GazExpense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPos = activeEnterprise?.isPointOfSale ?? false;

    // Utiliser le service pour les calculs
    final performanceData = GazFinancialCalculationService.calculateLast7DaysPerformance(
      sales,
      expenses,
    );

    return DashboardPerformanceChart(
      profitData: performanceData.profitData,
      expensesData: performanceData.expensesData,
      salesData: performanceData.salesData,
      showOnlySales: isPos,
    );
  }
}

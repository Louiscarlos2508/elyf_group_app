import 'package:flutter/material.dart';

import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/dashboard_performance_chart.dart';

/// Section du graphique de performance pour le dashboard.
class DashboardPerformanceSection extends StatelessWidget {
  const DashboardPerformanceSection({
    super.key,
    required this.sales,
    required this.expenses,
  });

  final List<GasSale> sales;
  final List<GazExpense> expenses;

  @override
  Widget build(BuildContext context) {
    // Utiliser le service pour les calculs
    final performanceData = GazCalculationService.calculateLast7DaysPerformance(
      sales,
      expenses,
    );

    return DashboardPerformanceChart(
      profitData: performanceData.profitData,
      expensesData: performanceData.expensesData,
      salesData: performanceData.salesData,
    );
  }
}

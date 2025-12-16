import 'dart:async';

import '../../domain/entities/expense_report_data.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/product_sales_summary.dart';
import '../../domain/entities/production_report_data.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/salary_report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/salary_repository.dart';
import '../../domain/repositories/sale_repository.dart';

class MockReportRepository implements ReportRepository {
  MockReportRepository({
    required this.salesRepository,
    required this.financeRepository,
    required this.salaryRepository,
    required this.productionSessionRepository,
  });

  final SaleRepository salesRepository;
  final FinanceRepository financeRepository;
  final SalaryRepository salaryRepository;
  final ProductionSessionRepository productionSessionRepository;

  @override
  Future<ReportData> fetchReportData(ReportPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Fetch sales for period
    final sales = await salesRepository.fetchSales();
    final periodSales = sales.where((sale) {
      return sale.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          sale.date.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate revenue
    final revenue = periodSales.fold(0, (sum, sale) => sum + sale.totalPrice);
    final collections = periodSales.fold(0, (sum, sale) => sum + sale.amountPaid);
    final collectionRate = revenue > 0 ? (collections / revenue) * 100 : 0.0;

    // Fetch expenses for period
    final expenses = await financeRepository.fetchRecentExpenses(limit: 1000);
    final periodExpenses = expenses.where((expense) {
      return expense.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();
    final expensesTotal = periodExpenses.fold(0, (sum, e) => sum + e.amountCfa);

    // Fetch salary payments for period
    final monthlyPayments = await salaryRepository.fetchMonthlySalaryPayments();
    final productionPayments = await salaryRepository.fetchProductionPayments();
    final periodMonthlyPayments = monthlyPayments.where((p) {
      return p.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          p.date.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();
    final periodProductionPayments = productionPayments.where((p) {
      return p.paymentDate.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          p.paymentDate.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();
    final monthlyTotal = periodMonthlyPayments.fold(0, (sum, p) => sum + p.amount);
    final productionTotal = periodProductionPayments.fold(0, (sum, p) => sum + p.totalAmount);
    final salariesTotal = monthlyTotal + productionTotal;

    final totalExpenses = expensesTotal + salariesTotal;
    final treasury = collections - totalExpenses;

    return ReportData(
      revenue: revenue,
      collections: collections,
      totalExpenses: totalExpenses,
      treasury: treasury,
      salesCount: periodSales.length,
      collectionRate: collectionRate,
    );
  }

  @override
  Future<List<Sale>> fetchSalesForPeriod(ReportPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final sales = await salesRepository.fetchSales();
    return sales.where((sale) {
      return sale.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          sale.date.isBefore(period.endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<List<ProductSalesSummary>> fetchProductSalesSummary(ReportPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final sales = await fetchSalesForPeriod(period);

    final productMap = <String, ProductSalesSummary>{};
    for (final sale in sales) {
      final existing = productMap[sale.productId];
      if (existing != null) {
        productMap[sale.productId] = ProductSalesSummary(
          productName: sale.productName,
          quantity: existing.quantity + sale.quantity,
          revenue: existing.revenue + sale.totalPrice,
        );
      } else {
        productMap[sale.productId] = ProductSalesSummary(
          productName: sale.productName,
          quantity: sale.quantity,
          revenue: sale.totalPrice,
        );
      }
    }

    return productMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  @override
  Future<ProductionReportData> fetchProductionReport(ReportPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final sessions = await productionSessionRepository.fetchSessions(
      startDate: period.startDate,
      endDate: period.endDate,
    );
    
    final periodSessions = sessions.where((session) {
      final sessionDate = DateTime(session.date.year, session.date.month, session.date.day);
      final start = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final end = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
      return (sessionDate.isAfter(start.subtract(const Duration(days: 1))) || sessionDate.isAtSameMomentAs(start)) &&
          (sessionDate.isBefore(end.add(const Duration(days: 1))) || sessionDate.isAtSameMomentAs(end));
    }).toList();

    final totalQuantity = periodSessions.fold(0, (sum, s) => sum + s.quantiteProduite);
    final totalBatches = periodSessions.length;
    final averageQuantityPerBatch = totalBatches > 0 ? totalQuantity / totalBatches : 0.0;
    
    // Calculer les totaux de coûts
    final totalBobinesCost = periodSessions.fold<int>(
      0,
      (sum, s) => sum + (s.coutBobines ?? 0),
    );
    final totalElectricityCost = periodSessions.fold<int>(
      0,
      (sum, s) => sum + (s.coutElectricite ?? 0),
    );
    final totalPersonnelCost = periodSessions.fold<int>(
      0,
      (sum, s) => sum + s.coutTotalPersonnel,
    );
    final totalCost = totalBobinesCost + totalElectricityCost + totalPersonnelCost;

    return ProductionReportData(
      totalQuantity: totalQuantity,
      totalBatches: totalBatches,
      averageQuantityPerBatch: averageQuantityPerBatch,
      productions: periodSessions,
      totalCost: totalCost,
      totalBobinesCost: totalBobinesCost,
      totalElectricityCost: totalElectricityCost,
      totalPersonnelCost: totalPersonnelCost,
    );
  }

  @override
  Future<ExpenseReportData> fetchExpenseReport(ReportPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final expenses = await financeRepository.fetchRecentExpenses(limit: 1000);
    // Filtrer les dépenses dans la période (inclusif des dates de début et fin)
    final periodExpenses = expenses.where((expense) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      final startDate = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final endDate = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
      
      return (expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              expenseDate.isBefore(endDate.add(const Duration(days: 1)))) ||
             expenseDate.isAtSameMomentAs(startDate) ||
             expenseDate.isAtSameMomentAs(endDate);
    }).toList();

    final totalAmount = periodExpenses.fold(0, (sum, e) => sum + e.amountCfa);
    
    final expensesByCategory = <ExpenseCategory, int>{};
    for (final expense in periodExpenses) {
      expensesByCategory[expense.category] = 
          (expensesByCategory[expense.category] ?? 0) + expense.amountCfa;
    }

    return ExpenseReportData(
      totalAmount: totalAmount,
      expensesByCategory: expensesByCategory,
      expenses: periodExpenses,
    );
  }

  @override
  Future<SalaryReportData> fetchSalaryReport(ReportPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final monthlyPayments = await salaryRepository.fetchMonthlySalaryPayments();
    final productionPayments = await salaryRepository.fetchProductionPayments();
    
    final periodMonthlyPayments = monthlyPayments.where((p) {
      final payDate = DateTime(p.date.year, p.date.month, p.date.day);
      final start = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final end = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
      return (payDate.isAfter(start.subtract(const Duration(days: 1))) || payDate.isAtSameMomentAs(start)) &&
          (payDate.isBefore(end.add(const Duration(days: 1))) || payDate.isAtSameMomentAs(end));
    }).toList();
    
    final periodProductionPayments = productionPayments.where((p) {
      final payDate = DateTime(p.paymentDate.year, p.paymentDate.month, p.paymentDate.day);
      final start = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final end = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
      return (payDate.isAfter(start.subtract(const Duration(days: 1))) || payDate.isAtSameMomentAs(start)) &&
          (payDate.isBefore(end.add(const Duration(days: 1))) || payDate.isAtSameMomentAs(end));
    }).toList();

    final totalMonthlySalaries = periodMonthlyPayments.fold(0, (sum, p) => sum + p.amount);
    final totalProductionPayments = periodProductionPayments.fold(0, (sum, p) => sum + p.totalAmount);
    final totalAmount = totalMonthlySalaries + totalProductionPayments;

    return SalaryReportData(
      totalMonthlySalaries: totalMonthlySalaries,
      totalProductionPayments: totalProductionPayments,
      totalAmount: totalAmount,
      monthlyPayments: periodMonthlyPayments,
      productionPayments: periodProductionPayments,
    );
  }
}


import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../domain/entities/expense_report_data.dart';
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

/// Offline-first repository for generating reports.
///
/// Aggregates data from other repositories to compute report metrics.
class ReportOfflineRepository implements ReportRepository {
  ReportOfflineRepository({
    required this.saleRepository,
    required this.productionSessionRepository,
    required this.financeRepository,
    required this.salaryRepository,
  });

  final SaleRepository saleRepository;
  final ProductionSessionRepository productionSessionRepository;
  final FinanceRepository financeRepository;
  final SalaryRepository salaryRepository;

  DateTime _getStartDate(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day);
      case ReportPeriod.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case ReportPeriod.month:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.year:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _getEndDate(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(
            yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      case ReportPeriod.week:
      case ReportPeriod.month:
      case ReportPeriod.year:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  bool _isInPeriod(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  @override
  Future<ReportData> fetchReportData(ReportPeriod period) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final sales = await saleRepository.fetchRecentSales(limit: 5000);
      final periodSales =
          sales.where((s) => _isInPeriod(s.date, start, end)).toList();

      final sessions = await productionSessionRepository.fetchSessions();
      final periodSessions = sessions
          .where((s) => _isInPeriod(s.startDate, start, end))
          .toList();

      final expenses =
          await financeRepository.fetchRecentExpenses(limit: 1000);
      final periodExpenses =
          expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

      final totalSales =
          periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
      final totalProduction = periodSessions.fold<int>(
          0, (sum, s) => sum + (s.totalProduced ?? 0));
      final totalExpenses =
          periodExpenses.fold<int>(0, (sum, e) => sum + e.amountCfa);

      return ReportData(
        period: period,
        totalSales: totalSales,
        totalProduction: totalProduction,
        totalExpenses: totalExpenses,
        salesCount: periodSales.length,
        productionCount: periodSessions.length,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching report data',
          name: 'ReportOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<List<Sale>> fetchSalesForPeriod(ReportPeriod period) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final sales = await saleRepository.fetchRecentSales(limit: 5000);
      return sales.where((s) => _isInPeriod(s.date, start, end)).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching sales for period',
          name: 'ReportOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<List<ProductSalesSummary>> fetchProductSalesSummary(
      ReportPeriod period) async {
    try {
      final sales = await fetchSalesForPeriod(period);

      final productSales = <String, ProductSalesSummary>{};
      for (final sale in sales) {
        for (final item in sale.items) {
          final existing = productSales[item.productId];
          if (existing != null) {
            productSales[item.productId] = ProductSalesSummary(
              productId: item.productId,
              productName: item.productName,
              quantitySold: existing.quantitySold + item.quantity,
              totalAmount: existing.totalAmount + item.totalPrice,
            );
          } else {
            productSales[item.productId] = ProductSalesSummary(
              productId: item.productId,
              productName: item.productName,
              quantitySold: item.quantity,
              totalAmount: item.totalPrice,
            );
          }
        }
      }

      final summaries = productSales.values.toList();
      summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return summaries;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching product sales summary',
          name: 'ReportOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<ProductionReportData> fetchProductionReport(
      ReportPeriod period) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final sessions = await productionSessionRepository.fetchSessions();
      final periodSessions = sessions
          .where((s) => _isInPeriod(s.startDate, start, end))
          .toList();

      final totalProduction = periodSessions.fold<int>(
          0, (sum, s) => sum + (s.totalProduced ?? 0));
      final completedSessions =
          periodSessions.where((s) => s.status.name == 'completed').length;

      return ProductionReportData(
        period: period,
        totalProduction: totalProduction,
        sessionsCount: periodSessions.length,
        completedSessions: completedSessions,
        averageProduction: periodSessions.isEmpty
            ? 0
            : totalProduction ~/ periodSessions.length,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching production report',
          name: 'ReportOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<ExpenseReportData> fetchExpenseReport(ReportPeriod period) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final expenses =
          await financeRepository.fetchRecentExpenses(limit: 5000);
      final periodExpenses =
          expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

      final totalAmount =
          periodExpenses.fold<int>(0, (sum, e) => sum + e.amountCfa);

      final byCategory = <String, int>{};
      for (final expense in periodExpenses) {
        final category = expense.category.name;
        byCategory[category] = (byCategory[category] ?? 0) + expense.amountCfa;
      }

      return ExpenseReportData(
        period: period,
        totalAmount: totalAmount,
        expensesCount: periodExpenses.length,
        byCategory: byCategory,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching expense report',
          name: 'ReportOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }

  @override
  Future<SalaryReportData> fetchSalaryReport(ReportPeriod period) async {
    try {
      final employees = await salaryRepository.fetchFixedEmployees();
      final salaryPayments = await salaryRepository.fetchMonthlySalaryPayments();
      final productionPayments =
          await salaryRepository.fetchProductionPayments();

      final totalFixedSalaries =
          salaryPayments.fold<int>(0, (sum, s) => sum + s.amount);
      final totalProductionPayments = productionPayments.fold<int>(
          0, (sum, p) => sum + p.totalAmount);

      return SalaryReportData(
        period: period,
        totalFixedSalaries: totalFixedSalaries,
        totalProductionPayments: totalProductionPayments,
        totalSalaries: totalFixedSalaries + totalProductionPayments,
        employeesCount: employees.length,
        paymentsCount: salaryPayments.length + productionPayments.length,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log('Error fetching salary report',
          name: 'ReportOfflineRepository',
          error: error,
          stackTrace: stackTrace);
      throw appException;
    }
  }
}

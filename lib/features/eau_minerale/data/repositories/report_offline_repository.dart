import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/expense_report_data.dart';
import '../../domain/entities/expense_record.dart' show ExpenseCategory;
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
import '../../domain/repositories/credit_repository.dart';
import '../../domain/entities/production_session_status.dart';

/// Offline-first repository for generating reports.
///
/// Aggregates data from other repositories to compute report metrics.
class ReportOfflineRepository implements ReportRepository {
  ReportOfflineRepository({
    required this.saleRepository,
    required this.productionSessionRepository,
    required this.financeRepository,
    required this.salaryRepository,
    required this.creditRepository,
  });

  final SaleRepository saleRepository;
  final ProductionSessionRepository productionSessionRepository;
  final FinanceRepository financeRepository;
  final SalaryRepository salaryRepository;
  final CreditRepository creditRepository;

  DateTime _getStartDate(ReportPeriod period, {DateTime? startDate}) {
    return startDate ?? period.startDate;
  }

  DateTime _getEndDate(ReportPeriod period, {DateTime? endDate}) {
    return endDate ?? period.endDate;
  }

  bool _isInPeriod(DateTime date, DateTime start, DateTime end) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  @override
  Future<ReportData> fetchReportData(ReportPeriod period) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final periodSales = await saleRepository.fetchSales(
        startDate: start,
        endDate: end,
      );

      final periodExpenses = await financeRepository.fetchExpenses(
        startDate: start,
        endDate: end,
      );

      final revenue = periodSales.fold<int>(0, (sum, s) => sum + s.totalPrice);
      final salesCollections = periodSales.fold<int>(
        0,
        (sum, s) => sum + s.amountPaid,
      );

      // Fetch credit recoveries for the period
      final creditPayments = await creditRepository.fetchPayments(
        startDate: start,
        endDate: end,
      );
      final creditRecoveries = creditPayments.fold<int>(0, (sum, p) => sum + p.amount);
      
      final totalCollections = salesCollections + creditRecoveries;

      final totalGeneralExpenses = periodExpenses.fold<int>(
        0,
        (sum, e) => sum + e.amountCfa,
      );

      // Calculate payroll (salaries + production payments)
      final salaryPayments = await salaryRepository.fetchMonthlySalaryPayments();
      final productionPayments = await salaryRepository.fetchProductionPayments();
      
      final periodSalaryPayments = salaryPayments
          .where((p) => _isInPeriod(p.date, start, end))
          .toList();
      final periodProductionPayments = productionPayments
          .where((p) => _isInPeriod(p.paymentDate, start, end))
          .toList();
          
      final totalSalaries =
          periodSalaryPayments.fold<int>(0, (sum, p) => sum + p.amount) +
          periodProductionPayments.fold<int>(
            0,
            (sum, p) => sum + p.totalAmount,
          );

      // Calculate session direct costs (Bobines + Electricity)
      final sessions = await productionSessionRepository.fetchSessions(
        startDate: start,
        endDate: end,
      );
      final periodSessions = sessions
          .where((s) => _isInPeriod(s.date, start, end) && s.status != ProductionSessionStatus.cancelled)
          .toList();
      final totalSessionCosts = periodSessions.fold<int>(0, (sum, s) {
        return sum + (s.coutBobines ?? 0) + (s.coutEmballages ?? 0) + (s.coutElectricite ?? 0);
      });

      final totalOutflows = totalGeneralExpenses + totalSalaries + totalSessionCosts;
      final treasury = totalCollections - totalOutflows;
      
      final collectionRate = revenue > 0
          ? (totalCollections / revenue) * 100.0
          : 0.0;

      return ReportData(
        revenue: revenue,
        collections: totalCollections,
        totalExpenses: totalOutflows,
        treasury: treasury,
        salesCount: periodSales.length,
        collectionRate: collectionRate,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching report data: ${appException.message}',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Sale>> fetchSalesForPeriod(ReportPeriod period) async {
    try {
      return await saleRepository.fetchSales(
        startDate: _getStartDate(period),
        endDate: _getEndDate(period),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching sales for period',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<ProductSalesSummary>> fetchProductSalesSummary(
    ReportPeriod period,
  ) async {
    try {
      final sales = await fetchSalesForPeriod(period);

      final productSales = <String, ProductSalesSummary>{};
      for (final sale in sales) {
        final existing = productSales[sale.productId];
        if (existing != null) {
          productSales[sale.productId] = ProductSalesSummary(
            productName: sale.productName,
            quantity: existing.quantity + sale.quantity,
            revenue: existing.revenue + sale.totalPrice,
          );
        } else {
          productSales[sale.productId] = ProductSalesSummary(
            productName: sale.productName,
            quantity: sale.quantity,
            revenue: sale.totalPrice,
          );
        }
      }

      final summaries = productSales.values.toList();
      summaries.sort((a, b) => b.revenue.compareTo(a.revenue));
      return summaries;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching product sales summary: ${appException.message}',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ProductionReportData> fetchProductionReport(
    ReportPeriod period,
  ) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final sessions = await productionSessionRepository.fetchSessions(
        startDate: start,
        endDate: end,
      );
      
      final periodSessions = sessions
          .where((s) => _isInPeriod(s.date, start, end) && s.status != ProductionSessionStatus.cancelled)
          .toList();

      final totalQuantity = periodSessions.fold<int>(
        0,
        (sum, s) {
           final dailySum = s.totalPacksProduitsJournalier;
           final finalQty = s.quantiteProduite;
           return sum + (dailySum > 0 ? dailySum : finalQty);
        },
      );
      final totalBatches = periodSessions.length;
      final averageQuantityPerBatch = totalBatches > 0
          ? totalQuantity / totalBatches
          : 0.0;

      // Calculate costs
      final totalBobinesCost = periodSessions.fold<int>(
        0,
        (sum, s) => sum + (s.coutBobines ?? 0),
      );
      final totalPackagingCost = periodSessions.fold<int>(
        0,
        (sum, s) => sum + (s.coutEmballages ?? 0),
      );
      final totalElectricityCost = periodSessions.fold<int>(
        0,
        (sum, s) => sum + (s.coutElectricite ?? 0),
      );
      final totalPersonnelCost = periodSessions.fold<int>(
        0,
        (sum, s) => sum + s.coutTotalPersonnel,
      );
      final totalCost =
          totalBobinesCost + totalPackagingCost + totalElectricityCost + totalPersonnelCost;

      return ProductionReportData(
        totalQuantity: totalQuantity,
        totalBatches: totalBatches,
        averageQuantityPerBatch: averageQuantityPerBatch,
        productions: periodSessions,
        totalCost: totalCost,
        totalBobinesCost: totalBobinesCost,
        totalPackagingCost: totalPackagingCost,
        totalElectricityCost: totalElectricityCost,
        totalPersonnelCost: totalPersonnelCost,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching production report',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ExpenseReportData> fetchExpenseReport(ReportPeriod period) async {
    try {
      final periodExpenses = await financeRepository.fetchExpenses(
        startDate: _getStartDate(period),
        endDate: _getEndDate(period),
      );

      final totalAmount = periodExpenses.fold<int>(
        0,
        (sum, e) => sum + e.amountCfa,
      );

      final expensesByCategory = <ExpenseCategory, int>{};
      for (final expense in periodExpenses) {
        final category = expense.category;
        expensesByCategory[category] =
            (expensesByCategory[category] ?? 0) + expense.amountCfa;
      }

      return ExpenseReportData(
        totalAmount: totalAmount,
        expensesByCategory: expensesByCategory,
        expenses: periodExpenses,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching expense report: ${appException.message}',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<SalaryReportData> fetchSalaryReport(ReportPeriod period) async {
    try {
      final start = _getStartDate(period);
      final end = _getEndDate(period);

      final salaryPayments = await salaryRepository
          .fetchMonthlySalaryPayments();
      final productionPayments = await salaryRepository
          .fetchProductionPayments();

      final periodSalaryPayments = salaryPayments
          .where((p) => _isInPeriod(p.date, start, end))
          .toList();
      final periodProductionPayments = productionPayments
          .where((p) => _isInPeriod(p.paymentDate, start, end))
          .toList();

      final totalMonthlySalaries = periodSalaryPayments.fold<int>(
        0,
        (sum, s) => sum + s.amount,
      );
      final totalProductionPayments = periodProductionPayments.fold<int>(
        0,
        (sum, p) => sum + p.totalAmount,
      );
      final totalAmount = totalMonthlySalaries + totalProductionPayments;

      return SalaryReportData(
        totalMonthlySalaries: totalMonthlySalaries,
        totalProductionPayments: totalProductionPayments,
        totalAmount: totalAmount,
        monthlyPayments: periodSalaryPayments,
        productionPayments: periodProductionPayments,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching salary report: ${appException.message}',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

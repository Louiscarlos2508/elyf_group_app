import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for generating reports.
/// 
/// This repository aggregates data from Sale, Purchase, and Expense
/// repositories to generate reports.
class ReportOfflineRepository implements ReportRepository {
  ReportOfflineRepository({
    required this.saleRepository,
    required this.purchaseRepository,
    required this.expenseRepository,
  });

  final SaleRepository saleRepository;
  final PurchaseRepository purchaseRepository;
  final ExpenseRepository expenseRepository;

  DateTime _getStartDate(ReportPeriod period, {DateTime? startDate}) {
    if (startDate != null) return startDate;
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case ReportPeriod.month:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.year:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.custom:
        return now.subtract(const Duration(days: 30));
    }
  }

  DateTime _getEndDate(ReportPeriod period, {DateTime? endDate}) {
    if (endDate != null) return endDate;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  bool _isInPeriod(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  @override
  Future<ReportData> getReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final sales = await saleRepository.fetchRecentSales(limit: 1000);
      final purchases = await purchaseRepository.fetchPurchases(limit: 1000);
      final expenses = await expenseRepository.fetchExpenses(limit: 1000);

      final periodSales =
          sales.where((s) => _isInPeriod(s.date, start, end)).toList();
      final periodPurchases =
          purchases.where((p) => _isInPeriod(p.date, start, end)).toList();
      final periodExpenses =
          expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

      final salesRevenue =
          periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
      final purchasesAmount =
          periodPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
      final expensesAmount =
          periodExpenses.fold<int>(0, (sum, e) => sum + e.amount);

      return ReportData(
        period: period,
        salesRevenue: salesRevenue,
        purchasesAmount: purchasesAmount,
        expensesAmount: expensesAmount,
        profit: salesRevenue - purchasesAmount - expensesAmount,
        salesCount: periodSales.length,
        purchasesCount: periodPurchases.length,
        expensesCount: periodExpenses.length,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting report data',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<SalesReportData> getSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final sales = await saleRepository.fetchRecentSales(limit: 1000);
      final periodSales =
          sales.where((s) => _isInPeriod(s.date, start, end)).toList();

      final totalRevenue =
          periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
      final totalItemsSold = periodSales.fold<int>(
          0, (sum, s) => sum + s.items.fold<int>(0, (is_, i) => is_ + i.quantity));

      final productSales = <String, ProductSalesSummary>{};
      for (final sale in periodSales) {
        for (final item in sale.items) {
          final existing = productSales[item.productId];
          if (existing != null) {
            productSales[item.productId] = ProductSalesSummary(
              productId: item.productId,
              productName: item.productName,
              quantitySold: existing.quantitySold + item.quantity,
              revenue: existing.revenue + item.totalPrice,
            );
          } else {
            productSales[item.productId] = ProductSalesSummary(
              productId: item.productId,
              productName: item.productName,
              quantitySold: item.quantity,
              revenue: item.totalPrice,
            );
          }
        }
      }

      final topProducts = productSales.values.toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      return SalesReportData(
        totalRevenue: totalRevenue,
        totalItemsSold: totalItemsSold,
        averageSaleAmount:
            periodSales.isEmpty ? 0 : totalRevenue ~/ periodSales.length,
        salesCount: periodSales.length,
        topProducts: topProducts.take(10).toList(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting sales report',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PurchasesReportData> getPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final purchases = await purchaseRepository.fetchPurchases(limit: 1000);
      final periodPurchases =
          purchases.where((p) => _isInPeriod(p.date, start, end)).toList();

      final totalAmount =
          periodPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
      final totalItemsPurchased = periodPurchases.fold<int>(
          0,
          (sum, p) =>
              sum + p.items.fold<int>(0, (is_, i) => is_ + i.quantity));

      final supplierTotals = <String, SupplierSummary>{};
      for (final purchase in periodPurchases) {
        final supplier = purchase.supplier ?? 'Non spécifié';
        final existing = supplierTotals[supplier];
        if (existing != null) {
          supplierTotals[supplier] = SupplierSummary(
            supplierName: supplier,
            totalAmount: existing.totalAmount + purchase.totalAmount,
            purchasesCount: existing.purchasesCount + 1,
          );
        } else {
          supplierTotals[supplier] = SupplierSummary(
            supplierName: supplier,
            totalAmount: purchase.totalAmount,
            purchasesCount: 1,
          );
        }
      }

      final topSuppliers = supplierTotals.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return PurchasesReportData(
        totalAmount: totalAmount,
        totalItemsPurchased: totalItemsPurchased,
        averagePurchaseAmount: periodPurchases.isEmpty
            ? 0
            : totalAmount ~/ periodPurchases.length,
        purchasesCount: periodPurchases.length,
        topSuppliers: topSuppliers.take(10).toList(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting purchases report',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ExpensesReportData> getExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final expenses = await expenseRepository.fetchExpenses(limit: 1000);
      final periodExpenses =
          expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

      final totalAmount =
          periodExpenses.fold<int>(0, (sum, e) => sum + e.amount);

      final byCategory = <String, int>{};
      for (final expense in periodExpenses) {
        final category = expense.category;
        byCategory[category] = (byCategory[category] ?? 0) + expense.amount;
      }

      return ExpensesReportData(
        totalAmount: totalAmount,
        expensesCount: periodExpenses.length,
        averageExpenseAmount:
            periodExpenses.isEmpty ? 0 : totalAmount ~/ periodExpenses.length,
        byCategory: byCategory,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting expenses report',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ProfitReportData> getProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final sales = await saleRepository.fetchRecentSales(limit: 1000);
      final purchases = await purchaseRepository.fetchPurchases(limit: 1000);
      final expenses = await expenseRepository.fetchExpenses(limit: 1000);

      final periodSales =
          sales.where((s) => _isInPeriod(s.date, start, end)).toList();
      final periodPurchases =
          purchases.where((p) => _isInPeriod(p.date, start, end)).toList();
      final periodExpenses =
          expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

      final totalRevenue =
          periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
      final totalCostOfGoodsSold =
          periodPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
      final totalExpenses =
          periodExpenses.fold<int>(0, (sum, e) => sum + e.amount);

      final grossProfit = totalRevenue - totalCostOfGoodsSold;
      final netProfit = grossProfit - totalExpenses;

      final grossMarginPercentage =
          totalRevenue == 0 ? 0.0 : (grossProfit / totalRevenue) * 100;
      final netMarginPercentage =
          totalRevenue == 0 ? 0.0 : (netProfit / totalRevenue) * 100;

      return ProfitReportData(
        totalRevenue: totalRevenue,
        totalCostOfGoodsSold: totalCostOfGoodsSold,
        totalExpenses: totalExpenses,
        grossProfit: grossProfit,
        netProfit: netProfit,
        grossMarginPercentage: grossMarginPercentage,
        netMarginPercentage: netMarginPercentage,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting profit report',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

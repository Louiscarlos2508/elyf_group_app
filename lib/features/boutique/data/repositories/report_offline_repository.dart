
import 'package:rxdart/rxdart.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/report_data.dart';
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

      final periodSales = await saleRepository.getSalesInPeriod(start, end);
      final periodPurchases = await purchaseRepository.getPurchasesInPeriod(start, end);
      final periodExpenses = await expenseRepository.getExpensesInPeriod(start, end);

      final salesRevenue = periodSales.fold<int>(
        0,
        (sum, s) => sum + s.totalAmount,
      );

      // Consolidate purchases and stock-related expenses
      final purchasesAmount = periodPurchases.fold<int>(
        0,
        (sum, p) => sum + p.totalAmount,
      );

      final stockExpenses = periodExpenses
          .where((e) => e.category == ExpenseCategory.stock)
          .fold<int>(0, (sum, e) => sum + e.amountCfa);

      final operationalExpenses = periodExpenses
          .where((e) => e.category != ExpenseCategory.stock)
          .fold<int>(0, (sum, e) => sum + e.amountCfa);

      // Total purchases = Itemized purchases + Stock category expenses
      final totalPurchases = purchasesAmount + stockExpenses;

      return ReportData(
        period: period,
        salesRevenue: salesRevenue,
        purchasesAmount: totalPurchases,
        expensesAmount: operationalExpenses,
        profit: salesRevenue - totalPurchases - operationalExpenses,
        salesCount: periodSales.length,
        purchasesCount: periodPurchases.length,
        expensesCount: periodExpenses.length,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting report data: ${appException.message}',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<FullBoutiqueReportData> getFullReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = _getStartDate(period, startDate: startDate);
    final end = _getEndDate(period, endDate: endDate);

    final general = await getReportData(period, startDate: start, endDate: end);
    final sales = await getSalesReport(period, startDate: start, endDate: end);
    final purchases = await getPurchasesReport(period, startDate: start, endDate: end);
    final expenses = await getExpensesReport(period, startDate: start, endDate: end);
    final profit = await getProfitReport(period, startDate: start, endDate: end);

    return FullBoutiqueReportData(
      general: general,
      sales: sales,
      purchases: purchases,
      expenses: expenses,
      profit: profit,
      startDate: start,
      endDate: end,
    );
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

      final periodSales = await saleRepository.getSalesInPeriod(start, end);

      final totalRevenue = periodSales.fold<int>(
        0,
        (sum, s) => sum + s.totalAmount,
      );
      final totalItemsSold = periodSales.fold<int>(
        0,
        (sum, s) => sum + s.items.fold<int>(0, (is_, i) => is_ + i.quantity),
      );

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
        averageSaleAmount: periodSales.isEmpty
            ? 0
            : totalRevenue ~/ periodSales.length,
        salesCount: periodSales.length,
        topProducts: topProducts.take(10).toList(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
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

      final periodPurchases = await purchaseRepository.getPurchasesInPeriod(start, end);
      final periodExpenses = await expenseRepository.getExpensesInPeriod(start, end);

      final purchasesAmount = periodPurchases.fold<int>(
        0,
        (sum, p) => sum + p.totalAmount,
      );

      final stockExpensesAmount = periodExpenses
          .where((e) => e.category == ExpenseCategory.stock)
          .fold<int>(0, (sum, e) => sum + e.amountCfa);

      final totalAmount = purchasesAmount + stockExpensesAmount;

      final totalItemsPurchased = periodPurchases.fold<int>(
        0,
        (sum, p) => sum + p.items.fold<int>(0, (is_, i) => is_ + i.quantity),
      );

      final supplierTotals = <String, SupplierSummary>{};
      for (final purchase in periodPurchases) {
        final supplier = purchase.supplierId ?? 'Non spécifié';
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

      // Add stock expenses as a generic supplier if there's any
      if (stockExpensesAmount > 0) {
        const stockLabel = 'Dépenses Stock Directes';
        final existing = supplierTotals[stockLabel];
        final stockExpensesCount = periodExpenses
            .where((e) => e.category == ExpenseCategory.stock)
            .length;
            
        if (existing != null) {
          supplierTotals[stockLabel] = SupplierSummary(
            supplierName: stockLabel,
            totalAmount: existing.totalAmount + stockExpensesAmount,
            purchasesCount: existing.purchasesCount + stockExpensesCount,
          );
        } else {
          supplierTotals[stockLabel] = SupplierSummary(
            supplierName: stockLabel,
            totalAmount: stockExpensesAmount,
            purchasesCount: stockExpensesCount,
          );
        }
      }

      final topSuppliers = supplierTotals.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return PurchasesReportData(
        totalAmount: totalAmount,
        totalItemsPurchased: totalItemsPurchased,
        averagePurchaseAmount: (periodPurchases.length + 
            periodExpenses.where((e) => e.category == ExpenseCategory.stock).length) == 0
            ? 0
            : totalAmount ~/ (periodPurchases.length + 
                periodExpenses.where((e) => e.category == ExpenseCategory.stock).length),
        purchasesCount: periodPurchases.length + 
            periodExpenses.where((e) => e.category == ExpenseCategory.stock).length,
        topSuppliers: topSuppliers.take(10).toList(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting purchases report: ${appException.message}',
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

      final allExpenses = await expenseRepository.getExpensesInPeriod(start, end);
      
      // Exclude stock expenses from the operational expenses report
      final operationalExpenses = allExpenses
          .where((e) => e.category != ExpenseCategory.stock)
          .toList();

      final totalAmount = operationalExpenses.fold<int>(
        0,
        (sum, e) => sum + e.amountCfa,
      );

      final byCategory = <String, int>{};
      for (final expense in operationalExpenses) {
        final categoryLabel = expense.category.name; 
        byCategory[categoryLabel] =
            (byCategory[categoryLabel] ?? 0) + expense.amountCfa;
      }

      return ExpensesReportData(
        totalAmount: totalAmount,
        expensesCount: operationalExpenses.length,
        averageExpenseAmount: operationalExpenses.isEmpty
            ? 0
            : totalAmount ~/ operationalExpenses.length,
        byCategory: byCategory,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting expenses report: ${appException.message}',
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

      final periodSales = await saleRepository.getSalesInPeriod(start, end);
      final periodPurchases = await purchaseRepository.getPurchasesInPeriod(start, end);
      final periodExpenses = await expenseRepository.getExpensesInPeriod(start, end);

      final totalRevenue = periodSales.fold<int>(
        0,
        (sum, s) => sum + s.totalAmount,
      );
      
      final purchasesAmount = periodPurchases.fold<int>(
        0,
        (sum, p) => sum + p.totalAmount,
      );

      final stockExpenses = periodExpenses
          .where((e) => e.category == ExpenseCategory.stock)
          .fold<int>(0, (sum, e) => sum + e.amountCfa);

      final totalCostOfGoodsSold = purchasesAmount + stockExpenses;

      final totalExpenses = periodExpenses
          .where((e) => e.category != ExpenseCategory.stock)
          .fold<int>(0, (sum, e) => sum + e.amountCfa);

      final grossProfit = totalRevenue - totalCostOfGoodsSold;
      final netProfit = grossProfit - totalExpenses;

      final grossMarginPercentage = totalRevenue == 0
          ? 0.0
          : (grossProfit / totalRevenue) * 100;
      final netMarginPercentage = totalRevenue == 0
          ? 0.0
          : (netProfit / totalRevenue) * 100;

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
      AppLogger.error(
        'Error getting profit report: ${appException.message}',
        name: 'ReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<ReportData> watchReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CombineLatestStream.combine3(
      saleRepository.watchRecentSales(limit: 1000),
      purchaseRepository.watchPurchases(limit: 1000),
      expenseRepository.watchExpenses(limit: 1000),
      (sales, purchases, expenses) {
        final start = _getStartDate(period, startDate: startDate);
        final end = _getEndDate(period, endDate: endDate);

        final periodSales = sales.where((s) => _isInPeriod(s.date, start, end)).toList();
        final periodPurchases = purchases.where((p) => _isInPeriod(p.date, start, end)).toList();
        final periodExpenses = expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

        final salesRevenue = periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
        
        final purchasesAmount = periodPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
        final stockExpenses = periodExpenses
            .where((e) => e.category == ExpenseCategory.stock)
            .fold<int>(0, (sum, e) => sum + e.amountCfa);
        final totalPurchases = purchasesAmount + stockExpenses;

        final operationalExpenses = periodExpenses
            .where((e) => e.category != ExpenseCategory.stock)
            .fold<int>(0, (sum, e) => sum + e.amountCfa);

        return ReportData(
          period: period,
          salesRevenue: salesRevenue,
          purchasesAmount: totalPurchases,
          expensesAmount: operationalExpenses,
          profit: salesRevenue - totalPurchases - operationalExpenses,
          salesCount: periodSales.length,
          purchasesCount: periodPurchases.length,
          expensesCount: periodExpenses.length,
        );
      },
    );
  }

  @override
  Stream<SalesReportData> watchSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return saleRepository.watchRecentSales(limit: 1000).map((sales) {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final periodSales = sales.where((s) => _isInPeriod(s.date, start, end)).toList();

      final totalRevenue = periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
      final totalItemsSold = periodSales.fold<int>(0, (sum, s) => sum + s.items.fold<int>(0, (is_, i) => is_ + i.quantity));

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

      final topProducts = productSales.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

      return SalesReportData(
        totalRevenue: totalRevenue,
        totalItemsSold: totalItemsSold,
        averageSaleAmount: periodSales.isEmpty ? 0 : totalRevenue ~/ periodSales.length,
        salesCount: periodSales.length,
        topProducts: topProducts.take(10).toList(),
      );
    });
  }

  @override
  Stream<PurchasesReportData> watchPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CombineLatestStream.combine2(
      purchaseRepository.watchPurchases(limit: 1000),
      expenseRepository.watchExpenses(limit: 1000),
      (purchases, expenses) {
        final start = _getStartDate(period, startDate: startDate);
        final end = _getEndDate(period, endDate: endDate);

        final periodPurchases = purchases.where((p) => _isInPeriod(p.date, start, end)).toList();
        final periodExpenses = expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

        final purchasesAmount = periodPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
        final stockExpensesAmount = periodExpenses
            .where((e) => e.category == ExpenseCategory.stock)
            .fold<int>(0, (sum, e) => sum + e.amountCfa);
        
        final totalAmount = purchasesAmount + stockExpensesAmount;
        
        final totalItemsPurchased = periodPurchases.fold<int>(0, (sum, p) => sum + p.items.fold<int>(0, (is_, i) => is_ + i.quantity));

        final supplierTotals = <String, SupplierSummary>{};
        for (final purchase in periodPurchases) {
          final supplier = purchase.supplierId ?? 'Non spécifié';
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
        
        if (stockExpensesAmount > 0) {
          const stockLabel = 'Dépenses Stock Directes';
          final existing = supplierTotals[stockLabel];
          final stockExpensesCount = periodExpenses
              .where((e) => e.category == ExpenseCategory.stock)
              .length;
              
          if (existing != null) {
            supplierTotals[stockLabel] = SupplierSummary(
              supplierName: stockLabel,
              totalAmount: existing.totalAmount + stockExpensesAmount,
              purchasesCount: existing.purchasesCount + stockExpensesCount,
            );
          } else {
            supplierTotals[stockLabel] = SupplierSummary(
              supplierName: stockLabel,
              totalAmount: stockExpensesAmount,
              purchasesCount: stockExpensesCount,
            );
          }
        }

        final topSuppliers = supplierTotals.values.toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        final stockCount = periodExpenses.where((e) => e.category == ExpenseCategory.stock).length;

        return PurchasesReportData(
          totalAmount: totalAmount,
          totalItemsPurchased: totalItemsPurchased,
          averagePurchaseAmount: (periodPurchases.length + stockCount) == 0 ? 0 : totalAmount ~/ (periodPurchases.length + stockCount),
          purchasesCount: periodPurchases.length + stockCount,
          topSuppliers: topSuppliers.take(10).toList(),
        );
      },
    );
  }

  @override
  Stream<ExpensesReportData> watchExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return expenseRepository.watchExpenses(limit: 1000).map((expenses) {
      final start = _getStartDate(period, startDate: startDate);
      final end = _getEndDate(period, endDate: endDate);

      final operationalExpenses = expenses
          .where((e) => _isInPeriod(e.date, start, end) && e.category != ExpenseCategory.stock)
          .toList();

      final totalAmount = operationalExpenses.fold<int>(0, (sum, e) => sum + e.amountCfa);

      final byCategory = <String, int>{};
      for (final expense in operationalExpenses) {
        final categoryLabel = expense.category.name;
        byCategory[categoryLabel] = (byCategory[categoryLabel] ?? 0) + expense.amountCfa;
      }

      return ExpensesReportData(
        totalAmount: totalAmount,
        expensesCount: operationalExpenses.length,
        averageExpenseAmount: operationalExpenses.isEmpty ? 0 : totalAmount ~/ operationalExpenses.length,
        byCategory: byCategory,
      );
    });
  }

  @override
  Stream<ProfitReportData> watchProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CombineLatestStream.combine3(
      saleRepository.watchRecentSales(limit: 1000),
      purchaseRepository.watchPurchases(limit: 1000),
      expenseRepository.watchExpenses(limit: 1000),
      (sales, purchases, expenses) {
        final start = _getStartDate(period, startDate: startDate);
        final end = _getEndDate(period, endDate: endDate);

        final periodSales = sales.where((s) => _isInPeriod(s.date, start, end)).toList();
        final periodPurchases = purchases.where((p) => _isInPeriod(p.date, start, end)).toList();
        final periodExpenses = expenses.where((e) => _isInPeriod(e.date, start, end)).toList();

        final totalRevenue = periodSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
        
        final purchasesAmount = periodPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
        final stockExpenses = periodExpenses
            .where((e) => e.category == ExpenseCategory.stock)
            .fold<int>(0, (sum, e) => sum + e.amountCfa);
        final totalCostOfGoodsSold = purchasesAmount + stockExpenses;

        final totalExpenses = periodExpenses
            .where((e) => e.category != ExpenseCategory.stock)
            .fold<int>(0, (sum, e) => sum + e.amountCfa);

        final grossProfit = totalRevenue - totalCostOfGoodsSold;
        final netProfit = grossProfit - totalExpenses;

        final grossMarginPercentage = totalRevenue == 0 ? 0.0 : (grossProfit / totalRevenue) * 100;
        final netMarginPercentage = totalRevenue == 0 ? 0.0 : (netProfit / totalRevenue) * 100;

        return ProfitReportData(
          totalRevenue: totalRevenue,
          totalCostOfGoodsSold: totalCostOfGoodsSold,
          totalExpenses: totalExpenses,
          grossProfit: grossProfit,
          netProfit: netProfit,
          grossMarginPercentage: grossMarginPercentage,
          netMarginPercentage: netMarginPercentage,
        );
      },
    );
  }

  @override
  Stream<FullBoutiqueReportData> watchFullReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CombineLatestStream.combine5(
      watchReportData(period, startDate: startDate, endDate: endDate),
      watchSalesReport(period, startDate: startDate, endDate: endDate),
      watchPurchasesReport(period, startDate: startDate, endDate: endDate),
      watchExpensesReport(period, startDate: startDate, endDate: endDate),
      watchProfitReport(period, startDate: startDate, endDate: endDate),
      (general, sales, purchases, expenses, profit) {
        final start = _getStartDate(period, startDate: startDate);
        final end = _getEndDate(period, endDate: endDate);
        return FullBoutiqueReportData(
          general: general,
          sales: sales,
          purchases: purchases,
          expenses: expenses,
          profit: profit,
          startDate: start,
          endDate: end,
        );
      },
    );
  }
}

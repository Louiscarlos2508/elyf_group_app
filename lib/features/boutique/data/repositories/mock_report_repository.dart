import 'dart:async';

import '../../domain/entities/expense.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import 'report_calculator.dart';

class MockReportRepository implements ReportRepository {
  MockReportRepository(
    this._saleRepository,
    this._purchaseRepository,
    this._expenseRepository,
    this._productRepository,
  );

  final SaleRepository _saleRepository;
  final PurchaseRepository _purchaseRepository;
  final ExpenseRepository _expenseRepository;
  final ProductRepository _productRepository;


  @override
  Future<ReportData> getReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final start = ReportCalculator.getStartDate(period, startDate);
    final end = ReportCalculator.getEndDate(period, endDate);
    
    final sales = await _saleRepository.fetchRecentSales(limit: 1000);
    final purchases = await _purchaseRepository.fetchPurchases(limit: 1000);
    final expenses = await _expenseRepository.fetchExpenses(limit: 1000);
    
    final filteredSales = ReportCalculator.filterSales(sales, start, end);
    final filteredPurchases = ReportCalculator.filterPurchases(purchases, start, end);
    final filteredExpenses = ReportCalculator.filterExpenses(expenses, start, end);
    
    final salesRevenue = filteredSales.fold(0, (sum, s) => sum + s.totalAmount);
    final purchasesAmount = filteredPurchases.fold(0, (sum, p) => sum + p.totalAmount);
    final expensesAmount = filteredExpenses.fold(0, (sum, e) => sum + e.amountCfa);
    final profit = salesRevenue - purchasesAmount - expensesAmount;
    
    return ReportData(
      period: period,
      salesRevenue: salesRevenue,
      purchasesAmount: purchasesAmount,
      expensesAmount: expensesAmount,
      profit: profit,
      salesCount: filteredSales.length,
      purchasesCount: filteredPurchases.length,
      expensesCount: filteredExpenses.length,
    );
  }

  @override
  Future<SalesReportData> getSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final start = ReportCalculator.getStartDate(period, startDate);
    final end = ReportCalculator.getEndDate(period, endDate);
    
    final sales = await _saleRepository.fetchRecentSales(limit: 1000);
    final filteredSales = ReportCalculator.filterSales(sales, start, end);
    
    final totalRevenue = filteredSales.fold(0, (sum, s) => sum + s.totalAmount);
    final totalItemsSold = filteredSales.fold(0, (sum, s) {
      return sum + s.items.fold(0, (itemSum, item) => itemSum + item.quantity);
    });
    
    // Calculate top products
    final productSales = <String, ProductSalesSummary>{};
    for (final sale in filteredSales) {
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
      averageSaleAmount: filteredSales.isEmpty ? 0 : totalRevenue ~/ filteredSales.length,
      salesCount: filteredSales.length,
      topProducts: topProducts.take(10).toList(),
    );
  }

  @override
  Future<PurchasesReportData> getPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final start = ReportCalculator.getStartDate(period, startDate);
    final end = ReportCalculator.getEndDate(period, endDate);
    
    final purchases = await _purchaseRepository.fetchPurchases(limit: 1000);
    final filteredPurchases = ReportCalculator.filterPurchases(purchases, start, end);
    
    final totalAmount = filteredPurchases.fold(0, (sum, p) => sum + p.totalAmount);
    final totalItemsPurchased = filteredPurchases.fold(0, (sum, p) {
      return sum + p.items.fold(0, (itemSum, item) => itemSum + item.quantity);
    });
    
    // Calculate top suppliers
    final supplierMap = <String, SupplierSummary>{};
    for (final purchase in filteredPurchases) {
      final supplier = purchase.supplier ?? 'Non spécifié';
      final existing = supplierMap[supplier];
      if (existing != null) {
        supplierMap[supplier] = SupplierSummary(
          supplierName: supplier,
          totalAmount: existing.totalAmount + purchase.totalAmount,
          purchasesCount: existing.purchasesCount + 1,
        );
      } else {
        supplierMap[supplier] = SupplierSummary(
          supplierName: supplier,
          totalAmount: purchase.totalAmount,
          purchasesCount: 1,
        );
      }
    }
    
    final topSuppliers = supplierMap.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    
    return PurchasesReportData(
      totalAmount: totalAmount,
      totalItemsPurchased: totalItemsPurchased,
      averagePurchaseAmount: filteredPurchases.isEmpty
          ? 0
          : totalAmount ~/ filteredPurchases.length,
      purchasesCount: filteredPurchases.length,
      topSuppliers: topSuppliers.take(10).toList(),
    );
  }

  @override
  Future<ExpensesReportData> getExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final start = ReportCalculator.getStartDate(period, startDate);
    final end = ReportCalculator.getEndDate(period, endDate);
    
    final expenses = await _expenseRepository.fetchExpenses(limit: 1000);
    final filteredExpenses = ReportCalculator.filterExpenses(expenses, start, end);
    
    final totalAmount = filteredExpenses.fold(0, (sum, e) => sum + e.amountCfa);
    
    final byCategory = <String, int>{};
    for (final expense in filteredExpenses) {
      final categoryName = ReportCalculator.getCategoryName(expense.category);
      byCategory[categoryName] = (byCategory[categoryName] ?? 0) + expense.amountCfa;
    }
    
    return ExpensesReportData(
      totalAmount: totalAmount,
      expensesCount: filteredExpenses.length,
      averageExpenseAmount: filteredExpenses.isEmpty
          ? 0
          : totalAmount ~/ filteredExpenses.length,
      byCategory: byCategory,
    );
  }

  @override
  Future<ProfitReportData> getProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final start = ReportCalculator.getStartDate(period, startDate);
    final end = ReportCalculator.getEndDate(period, endDate);
    
    final sales = await _saleRepository.fetchRecentSales(limit: 1000);
    final purchases = await _purchaseRepository.fetchPurchases(limit: 1000);
    final expenses = await _expenseRepository.fetchExpenses(limit: 1000);
    
    final filteredSales = ReportCalculator.filterSales(sales, start, end);
    final filteredPurchases = ReportCalculator.filterPurchases(purchases, start, end);
    final filteredExpenses = ReportCalculator.filterExpenses(expenses, start, end);
    
    final totalRevenue = filteredSales.fold(0, (sum, s) => sum + s.totalAmount);
    
    // Calculate COGS (Cost of Goods Sold) from purchases
    // For simplicity, we'll use total purchases as COGS
    // In a real system, you'd track which products were sold and their purchase prices
    final totalCostOfGoodsSold = filteredPurchases.fold(0, (sum, p) => sum + p.totalAmount);
    final totalExpenses = filteredExpenses.fold(0, (sum, e) => sum + e.amountCfa);
    
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
  }

}


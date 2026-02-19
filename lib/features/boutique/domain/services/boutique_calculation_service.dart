import '../entities/expense.dart';
import '../entities/purchase.dart';
import '../entities/sale.dart';
import '../entities/report_data.dart' show ProfitReportData, ReportPeriod;

/// Unified service for all calculations in the Boutique module.
/// 
/// Consolidates logic from DashboardCalculationService, ReportCalculationService,
/// and ReportCalculator to provide a single source of truth for business metrics.
class BoutiqueCalculationService {
  BoutiqueCalculationService();

  // --- Date Helpers ---

  /// Gets the start date based on the report period and optional custom start.
  DateTime getStartDate(ReportPeriod period, [DateTime? customStart]) {
    if (customStart != null) return customStart;
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
        return customStart ?? now.subtract(const Duration(days: 30));
    }
  }

  /// Gets the end date based on the report period and optional custom end.
  DateTime getEndDate(ReportPeriod period, [DateTime? customEnd]) {
    if (customEnd != null) return customEnd;
    return DateTime.now();
  }

  /// Gets month start date for a specific reference date.
  DateTime getMonthStart([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  // --- Filtering ---

  /// Filters sales by date range.
  List<Sale> filterSales(List<Sale> sales, DateTime start, DateTime end) {
    return sales.where((s) {
      final saleDate = DateTime(s.date.year, s.date.month, s.date.day);
      return saleDate.isAfter(start.subtract(const Duration(days: 1))) &&
          saleDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Filters purchases by date range.
  List<Purchase> filterPurchases(List<Purchase> purchases, DateTime start, DateTime end) {
    return purchases.where((p) {
      final purchaseDate = DateTime(p.date.year, p.date.month, p.date.day);
      return purchaseDate.isAfter(start.subtract(const Duration(days: 1))) &&
          purchaseDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Filters expenses by date range.
  List<Expense> filterExpenses(List<Expense> expenses, DateTime start, DateTime end) {
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // --- Dashboard Metrics ---

  /// Calculates today's dashboard metrics.
  DashboardTodayMetrics calculateTodayMetrics(List<Sale> sales, [DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaySales = sales.where((s) {
      final saleDate = DateTime(s.date.year, s.date.month, s.date.day);
      return saleDate.isAtSameMomentAs(today);
    }).toList();

    final revenue = todaySales.fold(0, (sum, s) => sum + s.totalAmount);
    final count = todaySales.length;
    final avgTicket = count > 0 ? revenue ~/ count : 0;

    final itemsCount = todaySales.fold(0, (sum, s) {
      return sum + s.items.fold(0, (itemSum, item) => itemSum + item.quantity.toInt());
    });

    final cashRevenue = todaySales.fold(0, (sum, s) => sum + s.cashAmount);
    final mobileMoneyRevenue = todaySales.fold(0, (sum, s) => sum + s.mobileMoneyAmount);

    return DashboardTodayMetrics(
      revenue: revenue,
      cashRevenue: cashRevenue,
      mobileMoneyRevenue: mobileMoneyRevenue,
      salesCount: count,
      averageTicket: avgTicket,
      itemsCount: itemsCount,
    );
  }

  /// Calculates monthly dashboard metrics.
  DashboardMonthlyMetrics calculateMonthlyMetrics({
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Purchase> purchases,
    DateTime? referenceDate,
  }) {
    final monthStart = getMonthStart(referenceDate);
    final reference = referenceDate ?? DateTime.now();
    
    final monthSales = sales.where((s) => s.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
    final monthExpenses = expenses.where((e) => e.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
    final monthPurchases = purchases.where((p) => p.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();

    final revenue = monthSales.fold(0, (sum, s) => sum + s.totalAmount);
    final purchasesAmount = monthPurchases.fold(0, (sum, p) => sum + p.totalAmount);
    
    final stockExpenses = monthExpenses
        .where((e) => e.category == ExpenseCategory.stock)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);
        
    final operationalExpenses = monthExpenses
        .where((e) => e.category != ExpenseCategory.stock)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    final totalCostOfGoods = purchasesAmount + stockExpenses;
    final profit = revenue - operationalExpenses - totalCostOfGoods;

    return DashboardMonthlyMetrics(
      revenue: revenue,
      salesCount: monthSales.length,
      purchasesAmount: totalCostOfGoods,
      expensesAmount: operationalExpenses,
      profit: profit,
    );
  }

  /// Calculates monthly expense metrics.
  MonthlyExpenseMetrics calculateMonthlyExpenseMetrics(List<Expense> expenses, [DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    final monthExpenses = expenses.where((e) {
      return e.date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1)));
    }).toList();

    final total = monthExpenses.fold(0, (sum, e) => sum + e.amountCfa);
    
    final byCategory = <ExpenseCategory, int>{};
    for (var cat in ExpenseCategory.values) {
      final catAmount = monthExpenses
          .where((e) => e.category == cat)
          .fold(0, (sum, e) => sum + e.amountCfa);
      if (catAmount > 0) {
        byCategory[cat] = catAmount;
      }
    }

    return MonthlyExpenseMetrics(
      totalAmount: total,
      byCategory: byCategory,
    );
  }

  // --- Profit Report Calculation ---

  /// Calculates profit report data for a period.
  ProfitReportData calculateProfitReportData({
    required List<Sale> filteredSales,
    required List<Purchase> filteredPurchases,
    required List<Expense> filteredExpenses,
  }) {
    final totalRevenue = filteredSales.fold<int>(0, (sum, s) => sum + s.totalAmount);
    
    final purchasesAmount = filteredPurchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
    final stockExpenses = filteredExpenses
        .where((e) => e.category == ExpenseCategory.stock)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    final totalCOGS = purchasesAmount + stockExpenses;
    final totalExpenses = filteredExpenses
        .where((e) => e.category != ExpenseCategory.stock)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    final grossProfit = totalRevenue - totalCOGS;
    final netProfit = grossProfit - totalExpenses;

    final grossMargin = totalRevenue == 0 ? 0.0 : (grossProfit / totalRevenue) * 100;
    final netMargin = totalRevenue == 0 ? 0.0 : (netProfit / totalRevenue) * 100;

    return ProfitReportData(
      totalRevenue: totalRevenue,
      totalCostOfGoodsSold: totalCOGS,
      totalExpenses: totalExpenses,
      grossProfit: grossProfit,
      netProfit: netProfit,
      grossMarginPercentage: grossMargin,
      netMarginPercentage: netMargin,
    );
  }

  // --- Category Labels ---

  String getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.stock: return 'Stock/Achats';
      case ExpenseCategory.rent: return 'Loyer';
      case ExpenseCategory.utilities: return 'Services publics';
      case ExpenseCategory.maintenance: return 'Maintenance';
      case ExpenseCategory.marketing: return 'Marketing';
      case ExpenseCategory.other: return 'Autres';
    }
  }
}

/// Metrics for today's dashboard.
class DashboardTodayMetrics {
  const DashboardTodayMetrics({
    required this.revenue,
    required this.cashRevenue,
    required this.mobileMoneyRevenue,
    required this.salesCount,
    required this.averageTicket,
    required this.itemsCount,
  });

  final int revenue;
  final int cashRevenue;
  final int mobileMoneyRevenue;
  final int salesCount;
  final int averageTicket;
  final int itemsCount;
}

/// Metrics for monthly dashboard.
class DashboardMonthlyMetrics {
  const DashboardMonthlyMetrics({
    required this.revenue,
    required this.salesCount,
    required this.purchasesAmount,
    required this.expensesAmount,
    required this.profit,
  });

  final int revenue;
  final int salesCount;
  final int purchasesAmount;
  final int expensesAmount;
  final int profit;

  bool get isProfit => profit >= 0;
}

/// Metrics for monthly expenses breakout.
class MonthlyExpenseMetrics {
  const MonthlyExpenseMetrics({
    required this.totalAmount,
    required this.byCategory,
  });

  final int totalAmount;
  final Map<ExpenseCategory, int> byCategory;
}

import '../entities/cylinder_stock.dart';
import '../entities/expense.dart';
import '../entities/gas_sale.dart';

/// Service for calculating dashboard metrics for the Gaz module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class GazDashboardCalculationService {
  GazDashboardCalculationService();

  /// Gets today's date (start of day).
  DateTime getToday([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Gets month start date.
  DateTime getMonthStart([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Gets week start date (Monday).
  DateTime getWeekStart([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  /// Calculates total stock from cylinder stocks.
  int calculateTotalStock(List<CylinderStock> stocks) {
    return stocks.fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Filters sales for today.
  List<GasSale> filterTodaySales(
    List<GasSale> sales, [
    DateTime? referenceDate,
  ]) {
    final today = getToday(referenceDate);
    return sales.where((s) {
      final saleDate = DateTime(
        s.saleDate.year,
        s.saleDate.month,
        s.saleDate.day,
      );
      return saleDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calculates today's revenue from sales.
  double calculateTodayRevenue(List<GasSale> sales, [DateTime? referenceDate]) {
    final todaySales = filterTodaySales(sales, referenceDate);
    return todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Filters sales for current week.
  List<GasSale> filterWeekSales(
    List<GasSale> sales, [
    DateTime? referenceDate,
  ]) {
    final weekStart = getWeekStart(referenceDate);
    return sales.where((s) {
      return s.saleDate.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Calculates week's revenue from sales.
  double calculateWeekRevenue(List<GasSale> sales, [DateTime? referenceDate]) {
    final weekSales = filterWeekSales(sales, referenceDate);
    return weekSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Filters sales for current month.
  List<GasSale> filterMonthSales(
    List<GasSale> sales, [
    DateTime? referenceDate,
  ]) {
    final monthStart = getMonthStart(referenceDate);
    return sales.where((s) {
      return s.saleDate.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Calculates month's revenue from sales.
  double calculateMonthRevenue(List<GasSale> sales, [DateTime? referenceDate]) {
    final monthSales = filterMonthSales(sales, referenceDate);
    return monthSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Filters expenses for current month.
  List<GazExpense> filterMonthExpenses(
    List<GazExpense> expenses, [
    DateTime? referenceDate,
  ]) {
    final monthStart = getMonthStart(referenceDate);
    return expenses.where((e) {
      return e.date.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Calculates month's expenses total.
  double calculateMonthExpensesTotal(
    List<GazExpense> expenses, [
    DateTime? referenceDate,
  ]) {
    final monthExpenses = filterMonthExpenses(expenses, referenceDate);
    return monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calculates month's profit (revenue - expenses).
  double calculateMonthProfit({
    required List<GasSale> sales,
    required List<GazExpense> expenses,
    DateTime? referenceDate,
  }) {
    final monthRevenue = calculateMonthRevenue(sales, referenceDate);
    final monthExpenses = calculateMonthExpensesTotal(expenses, referenceDate);
    return monthRevenue - monthExpenses;
  }

  /// Counts retail sales in month.
  int countMonthRetailSales(List<GasSale> sales, [DateTime? referenceDate]) {
    final monthSales = filterMonthSales(sales, referenceDate);
    return monthSales.where((s) => s.saleType == SaleType.retail).length;
  }

  /// Counts wholesale sales in month.
  int countMonthWholesaleSales(List<GasSale> sales, [DateTime? referenceDate]) {
    final monthSales = filterMonthSales(sales, referenceDate);
    return monthSales.where((s) => s.saleType == SaleType.wholesale).length;
  }

  /// Calculates today's metrics for dashboard.
  GazDashboardTodayMetrics calculateTodayMetrics(
    List<GasSale> sales, [
    DateTime? referenceDate,
  ]) {
    final todaySales = filterTodaySales(sales, referenceDate);
    final revenue = calculateTodayRevenue(sales, referenceDate);
    final count = todaySales.length;
    final avgTicket = count > 0 ? revenue / count : 0.0;

    return GazDashboardTodayMetrics(
      revenue: revenue,
      salesCount: count,
      averageTicket: avgTicket,
    );
  }

  /// Calculates all dashboard metrics.
  GazDashboardMetrics calculateMetrics({
    required List<CylinderStock> stocks,
    required List<GasSale> sales,
    required List<GazExpense> expenses,
    required int cylinderTypesCount,
    DateTime? referenceDate,
  }) {
    final totalStock = calculateTotalStock(stocks);
    final todaySales = filterTodaySales(sales, referenceDate);
    final todayRevenue = calculateTodayRevenue(sales, referenceDate);
    final weekSales = filterWeekSales(sales, referenceDate);
    final weekRevenue = calculateWeekRevenue(sales, referenceDate);
    final monthSales = filterMonthSales(sales, referenceDate);
    final monthRevenue = calculateMonthRevenue(sales, referenceDate);
    final monthExpenses = filterMonthExpenses(expenses, referenceDate);
    final monthExpensesTotal = calculateMonthExpensesTotal(
      expenses,
      referenceDate,
    );
    final monthProfit = calculateMonthProfit(
      sales: sales,
      expenses: expenses,
      referenceDate: referenceDate,
    );
    final retailSales = countMonthRetailSales(sales, referenceDate);
    final wholesaleSales = countMonthWholesaleSales(sales, referenceDate);

    return GazDashboardMetrics(
      totalStock: totalStock,
      cylinderTypesCount: cylinderTypesCount,
      todayRevenue: todayRevenue,
      todaySalesCount: todaySales.length,
      weekRevenue: weekRevenue,
      weekSalesCount: weekSales.length,
      monthRevenue: monthRevenue,
      monthSalesCount: monthSales.length,
      monthExpensesTotal: monthExpensesTotal,
      monthExpensesCount: monthExpenses.length,
      monthProfit: monthProfit,
      retailSalesCount: retailSales,
      wholesaleSalesCount: wholesaleSales,
    );
  }
}

/// Dashboard metrics for Gaz module.
class GazDashboardMetrics {
  const GazDashboardMetrics({
    required this.totalStock,
    required this.cylinderTypesCount,
    required this.todayRevenue,
    required this.todaySalesCount,
    required this.weekRevenue,
    required this.weekSalesCount,
    required this.monthRevenue,
    required this.monthSalesCount,
    required this.monthExpensesTotal,
    required this.monthExpensesCount,
    required this.monthProfit,
    required this.retailSalesCount,
    required this.wholesaleSalesCount,
  });

  final int totalStock;
  final int cylinderTypesCount;
  final double todayRevenue;
  final int todaySalesCount;
  final double weekRevenue;
  final int weekSalesCount;
  final double monthRevenue;
  final int monthSalesCount;
  final double monthExpensesTotal;
  final int monthExpensesCount;
  final double monthProfit;
  final int retailSalesCount;
  final int wholesaleSalesCount;

  bool get isProfit => monthProfit >= 0;
}

/// Today's dashboard metrics for Gaz.
class GazDashboardTodayMetrics {
  const GazDashboardTodayMetrics({
    required this.revenue,
    required this.salesCount,
    required this.averageTicket,
  });

  final double revenue;
  final int salesCount;
  final double averageTicket;
}

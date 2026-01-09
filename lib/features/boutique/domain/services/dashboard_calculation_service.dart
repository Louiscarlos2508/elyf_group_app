import '../entities/expense.dart';
import '../entities/purchase.dart';
import '../entities/sale.dart';

/// Service for calculating dashboard metrics for the boutique module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class BoutiqueDashboardCalculationService {
  BoutiqueDashboardCalculationService();

  /// Gets month start date for current month.
  DateTime getMonthStart([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Filters sales for today.
  List<Sale> filterTodaySales(List<Sale> sales, [DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales.where((s) {
      final saleDate = DateTime(s.date.year, s.date.month, s.date.day);
      return saleDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calculates today's revenue from sales.
  int calculateTodayRevenue(List<Sale> sales, [DateTime? referenceDate]) {
    final todaySales = filterTodaySales(sales, referenceDate);
    return todaySales.fold(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calculates average ticket for today.
  int calculateTodayAverageTicket(List<Sale> sales, [DateTime? referenceDate]) {
    final todaySales = filterTodaySales(sales, referenceDate);
    if (todaySales.isEmpty) return 0;
    final revenue = calculateTodayRevenue(sales, referenceDate);
    return revenue ~/ todaySales.length;
  }

  /// Calculates all today dashboard metrics.
  DashboardTodayMetrics calculateTodayMetrics(
    List<Sale> sales, [
    DateTime? referenceDate,
  ]) {
    final todaySales = filterTodaySales(sales, referenceDate);
    final revenue = todaySales.fold(0, (sum, s) => sum + s.totalAmount);
    final count = todaySales.length;
    final avgTicket = count > 0 ? revenue ~/ count : 0;

    return DashboardTodayMetrics(
      revenue: revenue,
      salesCount: count,
      averageTicket: avgTicket,
    );
  }

  /// Filters expenses for current month.
  List<Expense> filterMonthExpenses(
    List<Expense> expenses, [
    DateTime? referenceDate,
  ]) {
    final monthStart = getMonthStart(referenceDate);
    return expenses.where(
      (e) => e.date.isAfter(monthStart.subtract(const Duration(days: 1))),
    ).toList();
  }

  /// Calculates monthly expenses total.
  int calculateMonthlyExpensesTotal(
    List<Expense> expenses, [
    DateTime? referenceDate,
  ]) {
    final monthExpenses = filterMonthExpenses(expenses, referenceDate);
    return monthExpenses.fold(0, (sum, e) => sum + e.amountCfa);
  }

  /// Groups monthly expenses by category.
  Map<ExpenseCategory, int> groupExpensesByCategory(
    List<Expense> expenses, [
    DateTime? referenceDate,
  ]) {
    final monthExpenses = filterMonthExpenses(expenses, referenceDate);
    final byCategory = <ExpenseCategory, int>{};
    for (final expense in monthExpenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amountCfa;
    }
    return byCategory;
  }

  /// Calculates all monthly expense metrics.
  MonthlyExpenseMetrics calculateMonthlyExpenseMetrics(
    List<Expense> expenses, [
    DateTime? referenceDate,
  ]) {
    final monthlyTotal = calculateMonthlyExpensesTotal(expenses, referenceDate);
    final byCategory = groupExpensesByCategory(expenses, referenceDate);

    return MonthlyExpenseMetrics(
      totalAmount: monthlyTotal,
      byCategory: byCategory,
    );
  }

  /// Filters sales for current month.
  List<Sale> filterMonthSales(List<Sale> sales, [DateTime? referenceDate]) {
    final monthStart = getMonthStart(referenceDate);
    return sales.where(
      (s) => s.date.isAfter(monthStart.subtract(const Duration(days: 1))),
    ).toList();
  }

  /// Calculates monthly revenue from sales.
  int calculateMonthlyRevenue(List<Sale> sales, [DateTime? referenceDate]) {
    final monthSales = filterMonthSales(sales, referenceDate);
    return monthSales.fold(0, (sum, s) => sum + s.totalAmount);
  }

  /// Filters purchases for current month.
  List<Purchase> filterMonthPurchases(
    List<Purchase> purchases, [
    DateTime? referenceDate,
  ]) {
    final monthStart = getMonthStart(referenceDate);
    return purchases.where(
      (p) => p.date.isAfter(monthStart.subtract(const Duration(days: 1))),
    ).toList();
  }

  /// Calculates monthly purchases amount.
  int calculateMonthlyPurchasesAmount(
    List<Purchase> purchases, [
    DateTime? referenceDate,
  ]) {
    final monthPurchases = filterMonthPurchases(purchases, referenceDate);
    return monthPurchases.fold(0, (sum, p) => sum + p.totalAmount);
  }

  /// Calculates monthly profit (revenue - expenses - purchases).
  int calculateMonthlyProfit({
    required int revenue,
    required int expenses,
    required int purchases,
  }) {
    return revenue - expenses - purchases;
  }

  /// Calculates all monthly dashboard metrics.
  DashboardMonthlyMetrics calculateMonthlyMetrics({
    required List<Sale> sales,
    required List<Expense> expenses,
    required int purchasesAmount,
    DateTime? referenceDate,
  }) {
    final monthSales = filterMonthSales(sales, referenceDate);
    final revenue = monthSales.fold(0, (sum, s) => sum + s.totalAmount);
    final monthExpenses = calculateMonthlyExpensesTotal(expenses, referenceDate);
    final profit = calculateMonthlyProfit(
      revenue: revenue,
      expenses: monthExpenses,
      purchases: purchasesAmount,
    );

    return DashboardMonthlyMetrics(
      revenue: revenue,
      salesCount: monthSales.length,
      purchasesAmount: purchasesAmount,
      expensesAmount: monthExpenses,
      profit: profit,
    );
  }

  /// Calculates all monthly dashboard metrics with purchases list.
  DashboardMonthlyMetrics calculateMonthlyMetricsWithPurchases({
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Purchase> purchases,
    DateTime? referenceDate,
  }) {
    final purchasesAmount = calculateMonthlyPurchasesAmount(purchases, referenceDate);
    return calculateMonthlyMetrics(
      sales: sales,
      expenses: expenses,
      purchasesAmount: purchasesAmount,
      referenceDate: referenceDate,
    );
  }

  /// Gets category label for display.
  String getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.stock:
        return 'Stock/Achats';
      case ExpenseCategory.rent:
        return 'Loyer';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.other:
        return 'Autres';
    }
  }
}

/// Today's dashboard metrics.
class DashboardTodayMetrics {
  const DashboardTodayMetrics({
    required this.revenue,
    required this.salesCount,
    required this.averageTicket,
  });

  final int revenue;
  final int salesCount;
  final int averageTicket;
}

/// Monthly dashboard metrics.
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

/// Monthly expense metrics.
class MonthlyExpenseMetrics {
  const MonthlyExpenseMetrics({
    required this.totalAmount,
    required this.byCategory,
  });

  final int totalAmount;
  final Map<ExpenseCategory, int> byCategory;
}


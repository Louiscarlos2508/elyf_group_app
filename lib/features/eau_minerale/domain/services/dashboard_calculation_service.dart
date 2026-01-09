import '../../domain/entities/sale.dart';
import '../../domain/entities/customer_account.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_record.dart';

/// Service for calculating dashboard metrics.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class DashboardCalculationService {
  DashboardCalculationService();

  /// Calculates monthly revenue from sales.
  int calculateMonthlyRevenue(List<Sale> sales, DateTime monthStart) {
    final monthSales = sales.where((s) => s.date.isAfter(monthStart)).toList();
    return monthSales.fold(0, (sum, s) => sum + s.totalPrice);
  }

  /// Calculates today's collections (fully paid sales).
  int calculateTodayCollections(List<Sale> sales) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todaySales = sales
        .where((s) {
          final saleDate = DateTime(s.date.year, s.date.month, s.date.day);
          return saleDate.isAtSameMomentAs(todayStart) && s.isFullyPaid;
        })
        .toList();
    return todaySales.fold(0, (sum, s) => sum + s.amountPaid);
  }

  /// Calculates monthly collections (fully paid sales).
  int calculateMonthlyCollections(List<Sale> sales, DateTime monthStart) {
    final monthSales = sales
        .where((s) => s.date.isAfter(monthStart) && s.isFullyPaid)
        .toList();
    return monthSales.fold(0, (sum, s) => sum + s.amountPaid);
  }

  /// Calculates collection rate (collections / revenue * 100).
  double calculateCollectionRate(int revenue, int collections) {
    if (revenue == 0) return 0.0;
    return (collections / revenue) * 100;
  }

  /// Calculates total credits from customers.
  int calculateTotalCredits(List<CustomerAccount> customers) {
    return customers.fold(0, (sum, c) => sum + c.outstandingCredit);
  }

  /// Counts customers with active credits.
  int countCreditCustomers(List<CustomerAccount> customers) {
    return customers.where((c) => c.outstandingCredit > 0).length;
  }

  /// Calculates monthly result (collections - expenses).
  int calculateMonthlyResult(int collections, int expenses) {
    return collections - expenses;
  }

  /// Calculates monthly expenses.
  int calculateMonthlyExpenses(List<Expense> expenses, DateTime monthStart) {
    return expenses
        .where((e) => e.date.isAfter(monthStart))
        .fold(0, (sum, e) => sum + e.amount);
  }

  /// Calculates monthly expenses from ExpenseRecord list.
  int calculateMonthlyExpensesFromRecords(List<ExpenseRecord> expenses, DateTime monthStart) {
    return expenses
        .where((e) => e.date.isAfter(monthStart))
        .fold(0, (sum, e) => sum + e.amountCfa);
  }

  /// Counts monthly expenses.
  int countMonthlyExpenses(List<Expense> expenses, DateTime monthStart) {
    return expenses.where((e) => e.date.isAfter(monthStart)).length;
  }

  /// Counts monthly expenses from ExpenseRecord list.
  int countMonthlyExpensesFromRecords(List<ExpenseRecord> expenses, DateTime monthStart) {
    return expenses.where((e) => e.date.isAfter(monthStart)).length;
  }

  /// Gets month start date for current month.
  DateTime getMonthStart(DateTime now) {
    return DateTime(now.year, now.month, 1);
  }

  /// Calculates all monthly dashboard metrics.
  DashboardMonthlyMetrics calculateMonthlyMetrics({
    required List<Sale> sales,
    required List<CustomerAccount> customers,
    required List<Expense> expenses,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = getMonthStart(now);

    final revenue = calculateMonthlyRevenue(sales, monthStart);
    final collections = calculateMonthlyCollections(sales, monthStart);
    final collectionRate = calculateCollectionRate(revenue, collections);
    final totalCredits = calculateTotalCredits(customers);
    final creditCustomersCount = countCreditCustomers(customers);
    final monthExpenses = calculateMonthlyExpenses(expenses, monthStart);
    final monthResult = calculateMonthlyResult(collections, monthExpenses);

    final monthSales = sales.where((s) => s.date.isAfter(monthStart)).toList();
    final monthExpensesList = expenses.where((e) => e.date.isAfter(monthStart)).toList();

    return DashboardMonthlyMetrics(
      revenue: revenue,
      collections: collections,
      collectionRate: collectionRate,
      totalCredits: totalCredits,
      creditCustomersCount: creditCustomersCount,
      expenses: monthExpenses,
      result: monthResult,
      salesCount: monthSales.length,
      expensesCount: monthExpensesList.length,
    );
  }

  /// Calculates all monthly dashboard metrics from ExpenseRecord list.
  DashboardMonthlyMetrics calculateMonthlyMetricsFromRecords({
    required List<Sale> sales,
    required List<CustomerAccount> customers,
    required List<ExpenseRecord> expenses,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = getMonthStart(now);

    final revenue = calculateMonthlyRevenue(sales, monthStart);
    final collections = calculateMonthlyCollections(sales, monthStart);
    final collectionRate = calculateCollectionRate(revenue, collections);
    final totalCredits = calculateTotalCredits(customers);
    final creditCustomersCount = countCreditCustomers(customers);
    final monthExpenses = calculateMonthlyExpensesFromRecords(expenses, monthStart);
    final monthResult = calculateMonthlyResult(collections, monthExpenses);

    final monthSales = sales.where((s) => s.date.isAfter(monthStart)).toList();
    final monthExpensesList = expenses.where((e) => e.date.isAfter(monthStart)).toList();

    return DashboardMonthlyMetrics(
      revenue: revenue,
      collections: collections,
      collectionRate: collectionRate,
      totalCredits: totalCredits,
      creditCustomersCount: creditCustomersCount,
      expenses: monthExpenses,
      result: monthResult,
      salesCount: monthSales.length,
      expensesCount: monthExpensesList.length,
    );
  }
}

/// Monthly dashboard metrics.
class DashboardMonthlyMetrics {
  const DashboardMonthlyMetrics({
    required this.revenue,
    required this.collections,
    required this.collectionRate,
    required this.totalCredits,
    required this.creditCustomersCount,
    required this.expenses,
    required this.result,
    required this.salesCount,
    required this.expensesCount,
  });

  final int revenue;
  final int collections;
  final double collectionRate;
  final int totalCredits;
  final int creditCustomersCount;
  final int expenses;
  final int result;
  final int salesCount;
  final int expensesCount;

  bool get isProfit => result >= 0;
}


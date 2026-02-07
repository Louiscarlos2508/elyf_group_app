import '../../domain/entities/sale.dart';
import '../../domain/entities/customer_account.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';

/// Service for calculating dashboard metrics.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class DashboardCalculationService {
  DashboardCalculationService();

  /// Calculates monthly revenue from sales.
  int calculateMonthlyRevenue(List<Sale> sales, DateTime monthStart) {
    final monthSales = sales
        .where((s) =>
            s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart))
        .toList();
    return monthSales.fold(0, (sum, s) => sum + s.totalPrice);
  }

  /// Calculates today's collections (all payments made today).
  int calculateTodayCollections(List<Sale> sales) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todaySales = sales.where((s) {
      final saleDate = DateTime(s.date.year, s.date.month, s.date.day);
      return saleDate.isAtSameMomentAs(todayStart);
    }).toList();
    return todaySales.fold(0, (sum, s) => sum + s.amountPaid);
  }

  /// Calculates monthly collections (all payments made this month).
  /// Now includes credit recoveries.
  int calculateMonthlyCollections({
    required List<Sale> sales,
    required List<CreditPayment> creditPayments,
    required DateTime monthStart,
  }) {
    final monthSalesPayments = sales
        .where((s) =>
            s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart))
        .fold(0, (sum, s) => sum + s.amountPaid);

    final monthCreditRecoveries = creditPayments
        .where((p) =>
            p.date.isAfter(monthStart) || p.date.isAtSameMomentAs(monthStart))
        .fold(0, (sum, p) => sum + p.amount);

    return monthSalesPayments + monthCreditRecoveries;
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
  /// Now includes salary payments.
  int calculateMonthlyExpensesFromRecords({
    required List<ExpenseRecord> expenses,
    required List<SalaryPayment> salaryPayments,
    required List<ProductionPayment> productionPayments,
    List<ProductionSession> sessions = const [],
    required DateTime monthStart,
  }) {
    final generalExpenses = expenses
        .where((e) =>
            e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart))
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    final fixedSalaries = salaryPayments
        .where((p) =>
            p.date.isAfter(monthStart) || p.date.isAtSameMomentAs(monthStart))
        .fold<int>(0, (sum, p) => sum + p.amount);

    final prodSalaries = productionPayments
        .where((p) =>
            p.paymentDate.isAfter(monthStart) ||
            p.paymentDate.isAtSameMomentAs(monthStart))
        .fold<int>(0, (sum, p) => sum + p.totalAmount);

    // Calculate direct session costs (Bobines + Electricity) for sessions in this month
    final sessionCosts = sessions
        .where((s) =>
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)) &&
            s.status != ProductionSessionStatus.cancelled)
        .fold<int>(0, (sum, s) {
          final bobines = s.coutBobines ?? 0;
          final elec = s.coutElectricite ?? 0;
          return sum + bobines + elec;
        });

    return generalExpenses + fixedSalaries + prodSalaries + sessionCosts;
  }

  /// Counts monthly expenses.
  int countMonthlyExpenses(List<Expense> expenses, DateTime monthStart) {
    return expenses.where((e) => e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart)).length;
  }

  /// Counts monthly expenses from ExpenseRecord list.
  int countMonthlyExpensesFromRecords(
    List<ExpenseRecord> expenses,
    DateTime monthStart,
  ) {
    return expenses
        .where((e) =>
            e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart))
        .length;
  }

  /// Calculates monthly production volume, excluding cancelled sessions.
  int calculateMonthlyProduction(
    List<ProductionSession> sessions,
    DateTime monthStart,
  ) {
    return sessions
        .where((s) =>
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)) &&
            s.status != ProductionSessionStatus.cancelled)
        .fold<int>(0, (sum, s) {
          // Use daily production sum if available (more granular/real-time), 
          // otherwise fallback to finalized quantity.
          final dailySum = s.totalPacksProduitsJournalier;
          final finalQty = s.quantiteProduite;
          return sum + (dailySum > 0 ? dailySum : finalQty);
        });
  }

  /// Gets month start date for current month.
  DateTime getMonthStart(DateTime now) {
    return DateTime(now.year, now.month, 1);
  }

  /// Calculates all monthly dashboard metrics.
  DashboardMonthlyMetrics calculateMonthlyMetrics({
    required List<Sale> sales,
    required List<CreditPayment> creditPayments,
    required List<CustomerAccount> customers,
    required List<Expense> expenses,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = getMonthStart(now);

    final revenue = calculateMonthlyRevenue(sales, monthStart);
    final collections = calculateMonthlyCollections(
      sales: sales,
      creditPayments: creditPayments,
      monthStart: monthStart,
    );
    final collectionRate = calculateCollectionRate(revenue, collections);
    final totalCredits = calculateTotalCredits(customers);
    final creditCustomersCount = countCreditCustomers(customers);
    final monthExpenses = calculateMonthlyExpenses(expenses, monthStart);
    final monthResult = calculateMonthlyResult(collections, monthExpenses);

    final monthSales = sales
        .where((s) =>
            s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart))
        .toList();
    final monthExpensesList = expenses
        .where((e) =>
            e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart))
        .toList();

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
      productionVolume: 0, // Not available in old method
      sessionsCount: 0, // Not available in old method
    );
  }

  /// Calculates all monthly dashboard metrics from ExpenseRecord list.
  DashboardMonthlyMetrics calculateMonthlyMetricsFromRecords({
    required List<Sale> sales,
    required List<CreditPayment> creditPayments,
    required List<CustomerAccount> customers,
    required List<ExpenseRecord> expenses,
    required List<SalaryPayment> salaryPayments,
    required List<ProductionPayment> productionPayments,
    required List<ProductionSession> sessions,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = getMonthStart(now);

    final revenue = calculateMonthlyRevenue(sales, monthStart);
    final collections = calculateMonthlyCollections(
      sales: sales,
      creditPayments: creditPayments,
      monthStart: monthStart,
    );
    final collectionRate = calculateCollectionRate(revenue, collections);
    final totalCredits = calculateTotalCredits(customers);
    final creditCustomersCount = countCreditCustomers(customers);
    
    // Calculate expenses including session costs (bobines + elec)
    final monthExpenses = calculateMonthlyExpensesFromRecords(
      expenses: expenses,
      salaryPayments: salaryPayments,
      productionPayments: productionPayments,
      sessions: sessions, // Pass sessions for cost calculation
      monthStart: monthStart,
    );
    
    final monthResult = calculateMonthlyResult(collections, monthExpenses);

    final monthSales = sales
        .where((s) =>
            s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart))
        .toList();
        
    final monthExpensesListCount = countMonthlyExpensesFromRecords(expenses, monthStart);

    // Calculate production volume using daily updates for accuracy
    final productionVolume = calculateMonthlyProduction(sessions, monthStart);

    return DashboardMonthlyMetrics(
      revenue: revenue,
      collections: collections,
      collectionRate: collectionRate,
      totalCredits: totalCredits,
      creditCustomersCount: creditCustomersCount,
      expenses: monthExpenses,
      result: monthResult,
      salesCount: monthSales.length,
      expensesCount: monthExpensesListCount,
      productionVolume: productionVolume,
      sessionsCount: sessions
          .where((s) =>
              (s.date.isAfter(monthStart) ||
                  s.date.isAtSameMomentAs(monthStart)) &&
              s.status != ProductionSessionStatus.cancelled)
          .length,
    );
  }
  /// Calculates daily dashboard metrics.
  DailyDashboardMetrics calculateDailyMetrics({
    required List<Sale> sales,
    required List<CreditPayment> creditPayments,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // Filter for today
    final todaySales = sales.where((s) {
      final sDate = s.date;
      return sDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
             sDate.isBefore(startOfDay.add(const Duration(days: 1)));
    }).toList();

    final todayPayments = creditPayments.where((p) {
        final pDate = p.date;
        return pDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
               pDate.isBefore(startOfDay.add(const Duration(days: 1)));
    }).toList();

    // 1. Revenue (Total Price of Today's Sales)
    final revenue = todaySales.fold<int>(0, (sum, s) => sum + s.totalPrice);

    // 2. Collections from Today's Sales (Initial Payments)
    final collectionsFromSales = todaySales.fold<int>(0, (sum, s) => sum + s.amountPaid);

    // 3. Collections from Credit Payments (Recoveries made today)
    final collectionsFromCredit = todayPayments.fold<int>(0, (sum, p) => sum + p.amount);

    final totalCollections = collectionsFromSales + collectionsFromCredit;

    return DailyDashboardMetrics(
      revenue: revenue,
      collections: totalCollections,
      salesCount: todaySales.length,
      sales: todaySales,
    );
  }
}

/// Daily dashboard metrics.
class DailyDashboardMetrics {
  const DailyDashboardMetrics({
    required this.revenue,
    required this.collections,
    required this.salesCount,
    required this.sales,
  });

  final int revenue;
  final int collections;
  final int salesCount;
  final List<Sale> sales;
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
    required this.productionVolume,
    required this.sessionsCount,
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
  final int productionVolume;
  final int sessionsCount;

  bool get isProfit => result >= 0;
}

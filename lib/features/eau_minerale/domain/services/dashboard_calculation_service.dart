import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_account.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_record.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session_status.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

/// Service for calculating dashboard metrics.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class DashboardCalculationService {
  DashboardCalculationService();

  /// Calculates monthly revenue from sales.
  int calculateMonthlyRevenue(List<Sale> sales, DateTime monthStart) {
    final monthSales = sales
        .where((s) =>
            s.status != SaleStatus.voided &&
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)))
        .toList();
    return monthSales.fold(0, (sum, s) => sum + s.totalPrice);
  }

  /// Calculates today's collections (all payments made today).
  int calculateTodayCollections(List<Sale> sales) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todaySales = sales.where((s) {
      if (s.status == SaleStatus.voided) return false;
      final saleDate = DateTime(s.date.year, s.date.month, s.date.day);
      return saleDate.isAtSameMomentAs(todayStart);
    }).toList();
    return todaySales.fold(0, (sum, s) => sum + s.amountPaid);
  }

  /// Calculates monthly collections (all payments made this month).
  /// Now strictly using amountPaid from the sales collection.
  int calculateMonthlyCollections({
    required List<Sale> sales,
    required DateTime monthStart,
  }) {
    return sales
        .where((s) =>
            s.status != SaleStatus.voided &&
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)))
        .fold(0, (sum, s) => sum + s.amountPaid);
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

  /// Calculates monthly result (revenue - expenses) for an accrual view.
  int calculateMonthlyResult(int revenue, int expenses) {
    return revenue - expenses;
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
    // ExpenseRecords are the source of truth for all cash outflows (including salaries and purchases)
    // to avoid double counting.
    return expenses
        .where((e) => e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart))
        .fold<int>(0, (sum, e) => sum + e.amountCfa);
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
  double calculateMonthlyProduction(
    List<ProductionSession> sessions,
    DateTime monthStart,
  ) {
    return sessions
        .where((s) =>
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)) &&
            s.status != ProductionSessionStatus.cancelled)
        .fold<double>(0, (sum, s) {
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
      monthStart: monthStart,
    );
    final collectionRate = calculateCollectionRate(revenue, collections);
    final totalCredits = calculateTotalCredits(customers);
    final creditCustomersCount = countCreditCustomers(customers);
    final monthExpenses = calculateMonthlyExpenses(expenses, monthStart);
    final monthResult = calculateMonthlyResult(revenue, monthExpenses);

    final monthSales = sales
        .where((s) =>
            s.status != SaleStatus.voided &&
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)))
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
      productionVolume: 0.0, // Not available in old method
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
    List<TreasuryOperation> treasuryOperations = const [],
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = getMonthStart(now);

    final revenue = calculateMonthlyRevenue(sales, monthStart);
    
    // Strictly using Sales collection for monthly collections
    final int collections = calculateMonthlyCollections(
      sales: sales,
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
    
    final monthResult = calculateMonthlyResult(revenue, monthExpenses);

    final monthSales = sales
        .where((s) =>
            s.status != SaleStatus.voided &&
            (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)))
        .toList();
        
    final monthExpensesListCount = countMonthlyExpensesFromRecords(expenses, monthStart);

    // Calculate production volume using daily updates for accuracy
    final double productionVolume = calculateMonthlyProduction(sessions, monthStart);

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
    required List<ProductionSession> sessions,
    required List<ExpenseRecord> expenses,
    List<TreasuryOperation> treasuryOperations = const [],
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Filter for today
    final todaySales = sales.where((s) {
      final sDate = s.date;
      return s.status != SaleStatus.voided &&
             sDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
             sDate.isBefore(endOfDay);
    }).toList();

    final todayPayments = creditPayments.where((p) {
        final pDate = p.date;
        return pDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
               pDate.isBefore(endOfDay);
    }).toList();

    final todayExpenses = expenses.where((e) {
      final eDate = e.date;
      return eDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
             eDate.isBefore(endOfDay);
    }).toList();

    final todayOps = treasuryOperations.where((op) {
      final opDate = op.date;
      return opDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
             opDate.isBefore(endOfDay);
    }).toList();

    // 1. Revenue (Total Price of Today's Sales)
    final revenue = todaySales.fold<int>(0, (sum, s) => sum + s.totalPrice);

    // 2. Collections (Breakdown)
    // We now strictly use amountPaid from the sales collection for the "Collections" KPI
    final totalCollections = todaySales.fold<int>(0, (sum, s) => sum + s.amountPaid);
    
    final totalCashCollections = todaySales.fold<int>(0, (sum, s) => sum + s.cashAmount);
    final totalMMCollections = todaySales.fold<int>(0, (sum, s) => sum + s.orangeMoneyAmount);

    // Manual Operations (Apport/Supply) are tracked separately in apports metric below
    final cashApport = todayOps
        .where((op) => op.type == TreasuryOperationType.supply && 
                       op.toAccount == PaymentMethod.cash &&
                       op.referenceEntityType == null)
        .fold<int>(0, (sum, op) => sum + op.amount);
    final mmApport = todayOps
        .where((op) => op.type == TreasuryOperationType.supply && 
                       op.toAccount == PaymentMethod.mobileMoney &&
                       op.referenceEntityType == null)
        .fold<int>(0, (sum, op) => sum + op.amount);

    // 3. Production Volume Today
    final productionVolume = sessions.where((s) {
      final sDate = s.date;
      return sDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
             sDate.isBefore(endOfDay) &&
             s.status != ProductionSessionStatus.cancelled;
    }).fold<double>(0.0, (sum, s) {
      final dailySum = s.totalPacksProduitsJournalier;
      final finalQty = s.quantiteProduite;
      return sum + (dailySum > 0 ? dailySum : finalQty);
    });

    // 4. Expenses Today (Breakdown)
    final cashExpensesFromRecords = todayExpenses
        .where((e) => e.paymentMethod == PaymentMethod.cash)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);
    final mmExpensesFromRecords = todayExpenses
        .where((e) => e.paymentMethod == PaymentMethod.mobileMoney)
        .fold<int>(0, (sum, e) => sum + e.amountCfa);

    // Manual Operations: Retrait (Removal)
    final cashRetrait = todayOps
        .where((op) => op.type == TreasuryOperationType.removal && 
                       op.fromAccount == PaymentMethod.cash &&
                       op.referenceEntityType == null)
        .fold<int>(0, (sum, op) => sum + op.amount);
    final mmRetrait = todayOps
        .where((op) => op.type == TreasuryOperationType.removal && 
                       op.fromAccount == PaymentMethod.mobileMoney &&
                       op.referenceEntityType == null)
        .fold<int>(0, (sum, op) => sum + op.amount);

    final totalCashExpenses = cashExpensesFromRecords + cashRetrait;
    final totalMMExpenses = mmExpensesFromRecords + mmRetrait;
    final totalExpenses = totalCashExpenses + totalMMExpenses;

    return DailyDashboardMetrics(
      revenue: revenue,
      collections: totalCollections,
      cashCollections: totalCashCollections,
      mobileMoneyCollections: totalMMCollections,
      expenses: totalExpenses,
      cashExpenses: totalCashExpenses,
      mobileMoneyExpenses: totalMMExpenses,
      apports: cashApport + mmApport,
      retraits: cashRetrait + mmRetrait,
      salesCount: todaySales.length,
      sales: todaySales,
      productionVolume: productionVolume,
    );
  }

  /// Calculates cumulative treasury balances from all historical data.
  Map<String, int> calculateCumulativeBalances({
    required List<TreasuryOperation> treasuryOperations,
  }) {
    int cash = 0;
    int mm = 0;

    for (final op in treasuryOperations) {
      switch (op.type) {
        case TreasuryOperationType.supply:
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
        case TreasuryOperationType.removal:
          if (op.fromAccount == PaymentMethod.cash) cash -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mm -= op.amount;
          break;
        case TreasuryOperationType.transfer:
          if (op.fromAccount == PaymentMethod.cash) cash -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mm -= op.amount;
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
        case TreasuryOperationType.adjustment:
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
      }
    }

    return {
      'cash': cash,
      'mobileMoney': mm,
    };
  }
}

/// Daily dashboard metrics.
class DailyDashboardMetrics {
  const DailyDashboardMetrics({
    required this.revenue,
    required this.collections,
    this.cashCollections = 0,
    this.mobileMoneyCollections = 0,
    this.expenses = 0,
    this.cashExpenses = 0,
    this.mobileMoneyExpenses = 0,
    this.apports = 0,
    this.retraits = 0,
    required this.salesCount,
    required this.sales,
    this.productionVolume = 0.0,
  });

  final int revenue;
  final int collections;
  final int cashCollections;
  final int mobileMoneyCollections;
  final int expenses;
  final int cashExpenses;
  final int mobileMoneyExpenses;
  final int apports;
  final int retraits;
  final int salesCount;
  final List<Sale> sales;
  final double productionVolume;
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
  final double productionVolume;
  final int sessionsCount;

  bool get isProfit => result >= 0;
}

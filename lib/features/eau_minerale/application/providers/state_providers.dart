import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/salary_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_period.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_item.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/product_sales_summary.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_report_data.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/worker_monthly_stat.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/weekly_salary_info.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_credit.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/treasury_movement.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/adapters/expense_balance_adapter.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/dashboard_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/customer_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/pack_constants.dart';
import 'package:elyf_groupe_app/core/domain/entities/expense_balance_data.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

/// Provider pour récupérer le type de compteur configuré
final electricityMeterTypeProvider =
    FutureProvider.autoDispose<ElectricityMeterType>(
      (ref) async =>
          ref.watch(electricityMeterConfigServiceProvider).getMeterType(),
    );

/// Provider pour récupérer le taux d'électricité (CFA/kWh) configuré
final electricityRateProvider = FutureProvider.autoDispose<double>(
  (ref) async =>
      ref.watch(electricityMeterConfigServiceProvider).getElectricityRate(),
);

/// Provider pour récupérer toutes les machines (sans filtre).
final allMachinesProvider = FutureProvider.autoDispose<List<Machine>>((
  ref,
) async {
  return ref.read(machineControllerProvider).fetchMachines();
});

/// Provider pour récupérer tous les ouvriers journaliers.
final allDailyWorkersProvider = FutureProvider.autoDispose<List<DailyWorker>>((
  ref,
) async {
  return ref.read(dailyWorkerRepositoryProvider).fetchAllWorkers();
});

final activityStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(activityControllerProvider).fetchTodaySummary(),
);

final salesStateProvider = StreamProvider.autoDispose<SalesState>(
  (ref) => ref.watch(salesControllerProvider).watchRecentSales(),
);

final stockStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(stockControllerProvider).fetchSnapshot(),
);

final historicalStockStateProvider = FutureProvider.autoDispose
    .family<StockState, DateTime>((ref, date) async {
  return ref.watch(stockControllerProvider).fetchStockStateAtDate(date);
});

/// Stock d'un produit spécifique par son nom.
final productStockQuantityProvider = FutureProvider.autoDispose.family<int, String>((ref, productName) async {
  final state = await ref.watch(stockStateProvider.future);
  
  // Chercher par nom exact ou contenant le nom (cas insensible à la casse)
  final items = state.items
      .where((i) =>
          i.type == StockType.finishedGoods &&
          (i.name.toLowerCase() == productName.toLowerCase() ||
           i.name.toLowerCase().contains(productName.toLowerCase())))
      .toList();
      
  if (items.isNotEmpty) {
    // Priorité au nom exact si possible
    final exactMatch = items.where((i) => i.name.toLowerCase() == productName.toLowerCase()).toList();
    return (exactMatch.isNotEmpty ? exactMatch.first : items.first).quantity.toInt();
  }

  return 0;
});

/// Stock Pack (produits finis). Même source que Stock / Dashboard.
/// À utiliser pour les ventes au lieu de getCurrentStock.
/// @deprecated Utilisez productStockQuantityProvider(packName)
final packStockQuantityProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(productStockQuantityProvider(packName).future);
});

final clientsStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(clientsControllerProvider).fetchCustomers(),
);

final financesStateProvider = StreamProvider.autoDispose<FinancesState>(
  (ref) => ref.watch(financesControllerProvider).watchRecentExpenses(),
);

/// Provider pour le bilan des dépenses Eau Minérale.
final eauMineraleExpenseBalanceProvider =
    FutureProvider.autoDispose<List<ExpenseBalanceData>>((ref) async {
      final expenses = await ref
          .read(financesControllerProvider)
          .fetchRecentExpenses();
      final adapter = EauMineraleExpenseBalanceAdapter();
      return adapter.convertToBalanceData(expenses.expenses);
    });

final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async => ref.watch(productControllerProvider).fetchProducts(),
);

final rawMaterialsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final products = await ref.watch(productsProvider.future);
  return products.where((p) => p.type == ProductType.rawMaterial).toList();
});

final suppliersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(supplierControllerProvider).watchSuppliers(),
);

final purchasesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(purchaseControllerProvider).watchPurchases(),
);

final currentClosingSessionProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(closingControllerProvider).watchCurrentSession(),
);

final closingHistoryProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(closingControllerProvider).fetchHistory(),
);

final productionPeriodConfigProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionPeriodServiceProvider).getConfig(),
);

/// Paramètres pour filtrer les mouvements de stock
class StockMovementFiltersParams {
  const StockMovementFiltersParams({
    this.startDate,
    this.endDate,
    this.type,
    this.productName,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final StockMovementType? type;
  final String? productName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementFiltersParams &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          type == other.type &&
          productName == other.productName;

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      type.hashCode ^
      productName.hashCode;
}

/// Provider pour récupérer tous les mouvements de stock (bobines, emballages) avec filtres optionnels.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, StockMovementFiltersParams>((
      ref,
      params,
    ) async {
      final controller = ref.read(stockControllerProvider);
      return await controller.fetchAllMovements(
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

final productionSessionsStateProvider =
    StreamProvider.autoDispose<List<ProductionSession>>((ref) {
  return ref.watch(productionSessionControllerProvider).watchSessions();
});

final productionSessionsInPeriodProvider = FutureProvider.autoDispose
    .family<List<ProductionSession>, ({DateTime start, DateTime end})>(
  (ref, range) async {
    return ref.read(productionSessionControllerProvider).fetchSessions(
          startDate: range.start,
          endDate: range.end,
        );
  },
);

/// Provider pour récupérer une session par son ID.
final productionSessionDetailProvider = FutureProvider.autoDispose
    .family<ProductionSession, String>((ref, sessionId) async {
      final session = await ref
          .read(productionSessionControllerProvider)
          .fetchSessionById(sessionId);
      if (session == null) {
        throw NotFoundException(
          'Session non trouvée: $sessionId',
          'SESSION_NOT_FOUND',
        );
      }
      return session;
    });

/// Provider pour récupérer les ventes liées à une session.
final ventesParSessionProvider = FutureProvider.autoDispose
    .family<List<Sale>, String>((ref, sessionId) async {
      final session = await ref.read(
        productionSessionDetailProvider(sessionId).future,
      );
      
      // Utiliser fetchSales avec filtre de date pour récupérer toutes les ventes du jour
      final sessionDate = session.date;
      final startOfDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final allSales = await ref
          .read(saleRepositoryProvider)
          .fetchSales(startDate: startOfDay, endDate: endOfDay);

      // Filter sales belonging to this session
      return allSales.where((sale) {
        // 1. Explicit linkage (highest priority)
        if (sale.productionSessionId == sessionId) return true;
        
        // 2. If the sale is explicitly linked to ANOTHER session, exclude it
        if (sale.productionSessionId != null && sale.productionSessionId != '') return false;

        // 3. Chronological fallback: check if sale happened during the session window
        final isAfterStart = sale.date.isAfter(session.heureDebut) || 
                           sale.date.isAtSameMomentAs(session.heureDebut);
        
        // If session is still active, we include sales up to now
        final sessionEnd = session.heureFin;
        final isBeforeEnd = sessionEnd == null 
            ? true 
            : (sale.date.isBefore(sessionEnd) || sale.date.isAtSameMomentAs(sessionEnd));

        return isAfterStart && isBeforeEnd;
      }).toList();
    });

final salaryStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(salaryControllerProvider).fetchSalaries(),
);

final reportDataProvider = FutureProvider.autoDispose
    .family<ReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchReportData(period),
    );

final reportSalesProvider = FutureProvider.autoDispose
    .family<List<Sale>, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchSalesForPeriod(period),
    );

final reportProductSummaryProvider = FutureProvider.autoDispose
    .family<List<ProductSalesSummary>, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchProductSalesSummary(period),
    );

final reportProductionProvider = FutureProvider.autoDispose
    .family<ProductionReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchProductionReport(period),
    );

final reportExpenseProvider = FutureProvider.autoDispose
    .family<ExpenseReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchExpenseReport(period),
    );

final reportSalaryProvider = FutureProvider.autoDispose
    .family<SalaryReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchSalaryReport(period),
    );

/// Stream for Today's Sales (Real-time)
final todaySalesStreamProvider = StreamProvider.autoDispose<List<Sale>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
  
  return ref.watch(saleRepositoryProvider).watchSales(
    startDate: startOfDay,
    endDate: endOfDay,
  );
});

/// Stream for Today's Credit Payments (Real-time)
final todayPaymentsStreamProvider = StreamProvider.autoDispose<List<CreditPayment>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
  
  return ref.watch(creditRepositoryProvider).watchPayments(
    startDate: startOfDay,
    endDate: endOfDay,
  );
});

/// Stream for Monthly Credit Payments (Real-time).
final monthCreditPaymentsStreamProvider = StreamProvider.autoDispose<List<CreditPayment>>((ref) {
  final now = DateTime.now();
  final calculationService = ref.watch(dashboardCalculationServiceProvider);
  final monthStart = calculationService.getMonthStart(now);
  
  return ref.watch(creditRepositoryProvider).watchPayments(
    startDate: monthStart,
  );
});


/// Stream for Today's Production Sessions (Real-time)
final todaySessionsStreamProvider = StreamProvider.autoDispose<List<ProductionSession>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
  
  return ref.watch(productionSessionRepositoryProvider).watchSessions(
    startDate: startOfDay,
    endDate: endOfDay,
  );
});


/// Derived state for daily dashboard KPIs (Real-time).
/// Uses rxdart to stabilize emissions and avoid flickering.
final dailyDashboardSummaryProvider = StreamProvider.autoDispose<DailyDashboardMetrics>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

  final salesStream = ref.watch(saleRepositoryProvider).watchSales(
    startDate: startOfDay,
    endDate: endOfDay,
  );
  final paymentsStream = ref.watch(creditRepositoryProvider).watchPayments(
    startDate: startOfDay,
    endDate: endOfDay,
  );
  final sessionsStream = ref.watch(productionSessionRepositoryProvider).watchSessions(
    startDate: startOfDay,
    endDate: endOfDay,
  );
  final expensesStream = ref.watch(financeRepositoryProvider).watchExpenses();
  final treasuryStream = ref.watch(treasuryControllerProvider).watchOperations();

  return Rx.combineLatest5(
    salesStream,
    paymentsStream,
    sessionsStream,
    expensesStream,
    treasuryStream,
    (List<Sale> sales, List<CreditPayment> payments, List<ProductionSession> sessions, List<ExpenseRecord> expenses, List<TreasuryOperation> operations) {
      final calculationService = ref.read(dashboardCalculationServiceProvider);
      return calculationService.calculateDailyMetrics(
        sales: sales,
        creditPayments: payments,
        sessions: sessions,
        expenses: expenses,
        treasuryOperations: operations,
      );
    },
  ).debounceTime(const Duration(milliseconds: 500));
});

/// Derived state for the monthly dashboard KPIs.
/// This prevents heavy calculations in the UI and minimizes rebuilds.
class MonthlyDashboardSummary {
  const MonthlyDashboardSummary({
    required this.revenue,
    required this.collections,
    required this.production,
    required this.expenses,
    required this.result,
    required this.salesCount,
    required this.sessionsCount,
    required this.transactionsCount,
    required this.creditRecoveries,
    required this.salaryExpenses,
  });

  final int revenue;
  final int collections;
  final int production;
  final int expenses;
  final int result;
  final int salesCount;
  final int sessionsCount;
  final int transactionsCount;
  final int creditRecoveries;
  final int salaryExpenses;
}

final monthlyDashboardSummaryProvider =
    StreamProvider.autoDispose<MonthlyDashboardSummary>((ref) {
  final now = DateTime.now();
  final calculationService = ref.watch(dashboardCalculationServiceProvider);
  final monthStart = calculationService.getMonthStart(now);

  final salesStream = ref.watch(saleRepositoryProvider).watchSales();
  final financesStream = ref.watch(financeRepositoryProvider).watchExpenses();
  final sessionsStream = ref.watch(productionSessionRepositoryProvider).watchSessions();
  final creditPaymentsStream = ref.watch(creditRepositoryProvider).watchPayments(
    startDate: monthStart,
  );
  
  // For salaryState, we use ref.watch and convert to stream to include it in combineLatest
  final salaryStream = Stream.fromFuture(ref.watch(salaryStateProvider.future));

  return Rx.combineLatest5(
    salesStream,
    financesStream,
    sessionsStream,
    salaryStream,
    creditPaymentsStream,
    (List<Sale> sales, List<ExpenseRecord> expenses, List<ProductionSession> sessions, 
     SalaryState salaryState, List<CreditPayment> creditPayments) {
      return _calculateMonthlySummary(
        ref, 
        SalesState(sales: sales), 
        FinancesState(expenses: expenses), 
        sessions, 
        salaryState, 
        creditPayments,
      );
    },
  ).debounceTime(const Duration(milliseconds: 500));
});

/// Helper for monthly summary calculation to keep provider clean
MonthlyDashboardSummary _calculateMonthlySummary(
  Ref ref,
  SalesState sales,
  FinancesState finances,
  List<ProductionSession> sessions,
  SalaryState salaryState,
  List<CreditPayment> creditPayments,
) {
  final calculationService = ref.read(dashboardCalculationServiceProvider);
  final now = DateTime.now();
  final monthStart = calculationService.getMonthStart(now);

  final metrics = calculationService.calculateMonthlyMetricsFromRecords(
    sales: sales.sales,
    creditPayments: creditPayments,
    customers: [],
    expenses: finances.expenses,
    salaryPayments: salaryState.monthlySalaryPayments,
    productionPayments: salaryState.productionPayments,
    sessions: sessions,
    referenceDate: now,
  );

  final monthTransactions = finances.expenses
      .where((e) => e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart))
      .toList();

  final creditRecoveries = creditPayments.fold<int>(0, (sum, p) => sum + p.amount);
  
  final salaryExpenses = salaryState.monthlySalaryPayments
      .where((p) => p.date.isAfter(monthStart) || p.date.isAtSameMomentAs(monthStart))
      .fold<int>(0, (sum, p) => sum + p.amount) +
      salaryState.productionPayments
      .where((p) => p.paymentDate.isAfter(monthStart) || p.paymentDate.isAtSameMomentAs(monthStart))
      .fold<int>(0, (sum, p) => sum + p.totalAmount);

  return MonthlyDashboardSummary(
    revenue: metrics.revenue,
    collections: metrics.collections,
    production: metrics.productionVolume,
    expenses: metrics.expenses,
    result: metrics.result,
    salesCount: metrics.salesCount,
    sessionsCount: metrics.sessionsCount,
    transactionsCount: monthTransactions.length,
    creditRecoveries: creditRecoveries,
    salaryExpenses: salaryExpenses,
  );
}

final customerCreditsProvider = FutureProvider.autoDispose.family<List<Sale>, String>((ref, customerId) async {
  // Keep alive for 3 minutes to prevent rapid rebuilds
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return ref.read(creditRepositoryProvider).fetchCustomerAllCredits(customerId);
});

final customerCreditHistoryProvider = FutureProvider.autoDispose
    .family<List<({Sale sale, List<CreditPayment> payments})>, String>((
  ref,
  customerId,
) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  final creditRepo = ref.read(creditRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);
  final saleRepo = ref.read(saleRepositoryProvider);
  
  // 1. Fetch ALL sales to ensure we get full history (no limit)
  // We cannot rely on simple filtering because of potential ID mismatch (local vs remote)
  final allSales = await saleRepo.fetchSales();
  
  final targetSales = <Sale>[];
  
  // Optimisation: group by customerId first
  final salesByCustomerId = <String, List<Sale>>{};
  for (final sale in allSales) {
    salesByCustomerId.putIfAbsent(sale.customerId, () => []).add(sale);
  }

  // 2. Find sales belonging to this customer
  for (final entry in salesByCustomerId.entries) {
    final sId = entry.key;
    final sales = entry.value;

    if (sId == customerId) {
      targetSales.addAll(sales);
    } else {
      // Check if this sId resolves to the target customerId
      // e.g. sId is a local ID for the target customer
      final customer = await customerRepo.getCustomer(sId);
      if (customer != null && customer.id == customerId) {
        targetSales.addAll(sales);
      }
    }
  }
  
  // 3. Fetch payments for valid sales in parallel
  final results = await Future.wait(
    targetSales.map((sale) async {
      final payments = await creditRepo.fetchSalePayments(sale.id);
      return (sale: sale, payments: payments);
    }),
  );
  
  // Sort by date descending
  results.sort((a, b) => b.sale.date.compareTo(a.sale.date));
  
  return results;
});

final salePaymentsProvider =
    FutureProvider.autoDispose.family<List<CreditPayment>, String>((
  ref,
  saleId,
) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return ref.read(creditRepositoryProvider).fetchSalePayments(saleId);
});

final workerMonthlyStatsProvider =
    FutureProvider.autoDispose.family<List<WorkerMonthlyStat>, DateTime>((
  ref,
  month,
) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return ref.read(salaryControllerProvider).fetchWorkerMonthlyStats(month);
});

class CreditsDashboardState {
  const CreditsDashboardState({
    required this.mergedCustomers,
    required this.creditsMap,
    required this.totalCredit,
    required this.customersWithCredit,
  });

  final List<CustomerSummary> mergedCustomers;
  final Map<String, List<CustomerCredit>> creditsMap;
  final int totalCredit;
  final int customersWithCredit;
}

final creditsDashboardProvider = FutureProvider.autoDispose<CreditsDashboardState>((ref) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  final creditRepo = ref.read(creditRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);
  
  // 1. Get base customers (if available)
  final clientsState = await ref.watch(clientsStateProvider.future);
  final baseCustomers = clientsState.customers;

  final creditsMap = <String, List<CustomerCredit>>{};
  final extraCustomersMap = <String, CustomerSummary>{};

  // 2. Fetch all credit sales
  final allCreditSales = await creditRepo.fetchCreditSales();

  // 3. Group by customer
  final salesByCustomer = <String, List<Sale>>{};
  for (final sale in allCreditSales) {
    if (sale.customerId.isNotEmpty) {
      salesByCustomer.putIfAbsent(sale.customerId, () => []).add(sale);
    }
  }

  // 4. Process credits and fetch missing customers
  for (final entry in salesByCustomer.entries) {
    var customerId = entry.key;
    final creditSales = entry.value;

    try {
      CustomerSummary? customer;
      
      // Attempt to find in base list first
      try {
        customer = baseCustomers.firstWhere((c) => c.id == customerId);
      } catch (_) {}

      // If not found locally, fetch
      customer ??= await customerRepo.getCustomer(customerId);

      // If still null, create temporary
      if (customer == null && creditSales.isNotEmpty) {
        final firstSale = creditSales.first;
        customer = CustomerSummary(
          id: customerId,
          name: firstSale.customerName,
          phone: firstSale.customerPhone,
          totalCredit: 0,
          purchaseCount: creditSales.length,
          lastPurchaseDate: creditSales
              .map((s) => s.date)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          cnib: firstSale.customerCnib,
        );
      }

      if (customer == null) continue;
      
      customerId = customer.id;

      final credits = creditSales.map((sale) {
        return CustomerCredit(
          id: sale.id,
          enterpriseId: sale.enterpriseId,
          saleId: sale.id,
          amount: sale.totalPrice,
          amountPaid: sale.amountPaid,
          date: sale.date,
          dueDate: sale.date.add(const Duration(days: 30)),
        );
      }).toList();

      final validCredits = credits
          .where((c) => c.remainingAmount > 0)
          .toList();
          
      if (validCredits.isNotEmpty) {
        final existingCredits = creditsMap[customerId] ?? [];
        creditsMap[customerId] = [...existingCredits, ...validCredits];
        
        // If not in base list, add to extra
        if (!baseCustomers.any((c) => c.id == customerId)) {
           extraCustomersMap[customerId] = customer;
        }
      }
    } catch (e) {
      // Ignore errors for individual customers
    }
  }

  // 5. Merge customers
  final mergedCustomers = [...baseCustomers];
  for (final extra in extraCustomersMap.values) {
    if (!mergedCustomers.any((c) => c.id == extra.id)) {
      mergedCustomers.add(extra);
    }
  }

  // 6. Calculate KPIs
  int totalCreditReal = 0;
  int customersWithCreditReal = 0;

  for (final customer in mergedCustomers) {
    final credits = creditsMap[customer.id] ?? [];
    final totalCreditFromCredits = credits.fold<int>(
      0,
      (sum, credit) => sum + credit.remainingAmount,
    );
    if (totalCreditFromCredits > 0) {
      totalCreditReal += totalCreditFromCredits;
      customersWithCreditReal++;
    }
  }

  return CreditsDashboardState(
    mergedCustomers: mergedCustomers,
    creditsMap: creditsMap,
    totalCredit: totalCreditReal,
    customersWithCredit: customersWithCreditReal,
  );
});

final weeklySalariesProvider = FutureProvider.autoDispose.family<List<WeeklySalaryInfo>, DateTime>((ref, selectedWeek) async {
  // Helper to get start of week
  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  final debutSemaine = getStartOfWeek(selectedWeek);
  final finSemaine = debutSemaine.add(const Duration(days: 6));

  final sessions = await ref.watch(productionSessionsInPeriodProvider((
    start: debutSemaine,
    end: finSemaine,
  )).future);
  
  // Fetch payments to correctly filter paid workers
  final salaryState = await ref.watch(salaryStateProvider.future);
  final allPayments = salaryState.productionPayments;
  
  // Build a set of paid (workerId/workerName, dayId) keys
  final paidWorkerDayKeys = <String>{};
  
  for (final payment in allPayments) {
    final dayIds = payment.sourceProductionDayIds.toSet();
    
    for (final person in payment.persons) {
      for (final dayId in dayIds) {
        // Use ID if available, otherwise name (legacy)
        if (person.workerId != null) {
          paidWorkerDayKeys.add('id_${person.workerId}_$dayId');
        } else {
          paidWorkerDayKeys.add('name_${person.name}_$dayId');
        }
      }
    }
  }

  final allWorkers = await ref.watch(allDailyWorkersProvider.future);
  final workersMap = {for (var w in allWorkers) w.id: w};

  final salaries = <String, WeeklySalaryInfo>{};

  for (final session in sessions) {
    for (final day in session.productionDays) {
        // Filter by exact week
        if (day.date.isAfter(debutSemaine.subtract(const Duration(days: 1))) &&
            day.date.isBefore(finSemaine.add(const Duration(days: 1)))) {
          
          for (final workerId in day.personnelIds) {
             final worker = workersMap[workerId];
             final workerName = worker?.name ?? 'Ouvrier inconnu ($workerId)';
             
             // CHECK IF THIS WORKER IS PAID FOR THIS DAY (by ID or by Name as fallback)
             final isPaidById = paidWorkerDayKeys.contains('id_${workerId}_${day.id}');
             final isPaidByName = paidWorkerDayKeys.contains('name_${workerName}_${day.id}');
             
             if (isPaidById || isPaidByName) {
               continue; 
             }
             
             final tauxJour = worker?.salaireJournalier ?? day.salaireJournalierParPersonne;
             
             if (!salaries.containsKey(workerId)) {
              salaries[workerId] = WeeklySalaryInfo(
                workerId: workerId,
                workerName: workerName,
                daysWorked: 0,
                dailySalary: tauxJour,
                totalSalary: 0,
                productionDayIds: [],
              );
            }

            final info = salaries[workerId]!;
            salaries[workerId] = WeeklySalaryInfo(
              workerId: workerId,
              workerName: workerName,
              daysWorked: info.daysWorked + 1,
              dailySalary: tauxJour,
              totalSalary: info.totalSalary + tauxJour,
              productionDayIds: [...info.productionDayIds, day.id],
            );
          }
        }
    }
  }
  return salaries.values.toList();
});

/// Provider pour l'historique de la trésorerie (Ventes + Décaisssements + Recouvrements)
final treasuryHistoryProvider = StreamProvider.autoDispose<List<TreasuryMovement>>((ref) {
  final salesStream = ref.watch(salesControllerProvider).watchRecentSales().map((state) => state.sales);
  final paymentsStream = ref.watch(clientsControllerProvider).watchAllCreditPayments();
  final expensesStream = ref.watch(financesControllerProvider).watchExpenses();
  final manualOpsStream = ref.watch(treasuryControllerProvider).watchOperations();

  return Rx.combineLatest4(
    salesStream,
    paymentsStream,
    expensesStream,
    manualOpsStream,
    (List<Sale> sales, List<CreditPayment> payments, List<ExpenseRecord> expenses, List<TreasuryOperation> manualOps) {
      final movements = <TreasuryMovement>[];

      // 1. Ajouter les ventes (peuvent être splittées Cash/MM)
      for (final sale in sales) {
        if (sale.cashAmount > 0) {
          movements.add(TreasuryMovement(
            id: 'sale_cash_${sale.id}',
            date: sale.date,
            amount: sale.cashAmount,
            label: 'Vente: ${sale.customerName}',
            category: 'Vente',
            method: PaymentMethod.cash,
            isIncome: true,
            originalEntity: sale,
          ));
        }
        if (sale.orangeMoneyAmount > 0) {
          movements.add(TreasuryMovement(
            id: 'sale_mm_${sale.id}',
            date: sale.date,
            amount: sale.orangeMoneyAmount,
            label: 'Vente: ${sale.customerName}',
            category: 'Vente',
            method: PaymentMethod.mobileMoney,
            isIncome: true,
            originalEntity: sale,
          ));
        }
      }

      // 2. Ajouter les recouvrements de crédits
      for (final payment in payments) {
        if (payment.cashAmount > 0) {
          movements.add(TreasuryMovement(
            id: 'pay_cash_${payment.id}',
            date: payment.date,
            amount: payment.cashAmount,
            label: 'Recouvrement',
            category: 'Crédit',
            method: PaymentMethod.cash,
            isIncome: true,
            originalEntity: payment,
          ));
        }
        if (payment.orangeMoneyAmount > 0) {
          movements.add(TreasuryMovement(
            id: 'pay_mm_${payment.id}',
            date: payment.date,
            amount: payment.orangeMoneyAmount,
            label: 'Recouvrement',
            category: 'Crédit',
            method: PaymentMethod.mobileMoney,
            isIncome: true,
            originalEntity: payment,
          ));
        }
      }

      // 3. Ajouter les dépenses
      for (final expense in expenses) {
        movements.add(TreasuryMovement(
          id: 'exp_${expense.id}',
          date: expense.date,
          amount: expense.amountCfa,
          label: expense.label,
          category: 'Dépense',
          method: expense.paymentMethod,
          isIncome: false,
          originalEntity: expense,
        ));
      }

      // 4. Ajouter les opérations manuelles (Filtrer les liens pour éviter les doublons)
      for (final op in manualOps) {
        // On ignore les opérations liées à une entité métier (vente, dépense, etc.)
        // car elles sont déjà ajoutées par les flux spécifiques ci-dessus.
        if (op.referenceEntityId != null && op.referenceEntityId!.isNotEmpty) {
          continue;
        }

        final isIncome = op.type == TreasuryOperationType.supply || 
                        (op.type == TreasuryOperationType.transfer && op.toAccount != null && op.fromAccount == null);
        
        movements.add(TreasuryMovement(
          id: 'manual_${op.id}',
          date: op.date,
          amount: op.amount,
          label: op.reason ?? _getManualOpLabel(op.type),
          category: 'Trésorerie',
          method: op.toAccount ?? op.fromAccount ?? PaymentMethod.cash,
          isIncome: isIncome,
          originalEntity: op,
        ));
      }

      // Trier par date décroissante
      movements.sort((a, b) => b.date.compareTo(a.date));

      return movements.take(100).toList();
    },
  ).debounceTime(const Duration(milliseconds: 500));
});

String _getManualOpLabel(TreasuryOperationType type) {
  switch (type) {
    case TreasuryOperationType.supply: return 'Apport';
    case TreasuryOperationType.removal: return 'Retrait';
    case TreasuryOperationType.transfer: return 'Transfert';
    case TreasuryOperationType.adjustment: return 'Ajustement';
  }
}

final treasuryOperationsProvider = StreamProvider.autoDispose<List<TreasuryOperation>>(
  (ref) => ref.watch(treasuryControllerProvider).watchOperations(),
);

final treasuryBalancesProvider = StreamProvider.autoDispose<Map<String, int>>(
  (ref) => ref.watch(treasuryControllerProvider).watchBalances(),
);

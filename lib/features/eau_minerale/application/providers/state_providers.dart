import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/domain/entities/expense_balance_data.dart';
import '../../domain/adapters/expense_balance_adapter.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/electricity_meter_type.dart';
import '../../domain/entities/expense_report_data.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_sales_summary.dart';
import '../../domain/entities/production_report_data.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/salary_report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/worker_monthly_stat.dart';
import '../../domain/pack_constants.dart';
import 'controller_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/entities/weekly_salary_info.dart';

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

final salesStateProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(salesControllerProvider).watchRecentSales(),
);

final stockStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(stockControllerProvider).fetchSnapshot(),
);

/// Stock Pack (produits finis). Même source que Stock / Dashboard.
/// À utiliser pour les ventes au lieu de getCurrentStock.
final packStockQuantityProvider = FutureProvider.autoDispose<int>((ref) async {
  final state = await ref.watch(stockStateProvider.future);
  
  // 1. Chercher ID pack-1 ou nom contenant 'pack'
  final fg = state.items
      .where((i) =>
          i.type == StockType.finishedGoods &&
          (i.id == packStockItemId || i.name.toLowerCase().contains(packName.toLowerCase())))
      .toList();
      
  if (fg.isNotEmpty) {
    final pack = fg.any((i) => i.id == packStockItemId)
        ? fg.firstWhere((i) => i.id == packStockItemId)
        : fg.first;
    return pack.quantity.toInt();
  }

  // 2. Fallback: Si un seul item fini existe, c'est lui le "Pack"
  final allFG = state.items.where((i) => i.type == StockType.finishedGoods).toList();
  if (allFG.length == 1) return allFG.first.quantity.toInt();

  return 0;
});

final clientsStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(clientsControllerProvider).fetchCustomers(),
);

final financesStateProvider = StreamProvider.autoDispose(
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

      return allSales;
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

/// Derived state for daily dashboard KPIs.
class DailyDashboardSummary {
  const DailyDashboardSummary({
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

final dailyDashboardSummaryProvider = FutureProvider.autoDispose<DailyDashboardSummary>((ref) async {
  // 1. Fetch sales (using salesStateProvider which calls fetchRecentSales - assumes it fetches ALL or relevant sales)
  // Actually, SalesState.sales contains sales sorted by date.
  // We need to ensure we have ALL sales for "Today" and credit payments for "Today".
  
  final salesState = await ref.watch(salesStateProvider.future);
  final creditRepo = ref.watch(creditRepositoryProvider);
  
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

  // 2. Filter Sales for Today
  final todaySales = salesState.sales.where((s) {
    return s.date.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
           s.date.isBefore(endOfDay.add(const Duration(milliseconds: 1)));
  }).toList();

  // 3. Calculate Revenue (Total Price of Today's Sales)
  final revenue = todaySales.fold<int>(0, (sum, s) => sum + s.totalPrice);

  // 4. Calculate Collections from Today's Sales (Initial Payments)
  // We use cashAmount + orangeMoneyAmount which represent the payment made AT THE MOMENT OF SALE.
  final collectionsFromSales = todaySales.fold<int>(0, (sum, s) => sum + s.cashAmount + s.orangeMoneyAmount);

  // 5. Fetch Credit Payments for Today (Recoveries)
  // These are payments made today, potentially for past sales OR current sales (if recorded as credit payment).
  // Note: Standard flow for initial payment is stored in Sale.
  // Standard flow for debt payment is CreditPayment.
  // We must ensure we don't double count if a CreditPayment is created for the initial payment.
  // Currently, the app seems to NOT create CreditPayment for initial payment automatically in SaleOfflineRepository.
  
  final todayCreditPayments = await creditRepo.fetchPayments(
    startDate: startOfDay,
    endDate: endOfDay,
  );

  final collectionsFromCredit = todayCreditPayments.fold<int>(0, (sum, p) => sum + p.amount);

  final totalCollections = collectionsFromSales + collectionsFromCredit;

  return DailyDashboardSummary(
    revenue: revenue,
    collections: totalCollections,
    salesCount: todaySales.length,
    sales: todaySales,
  );
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
    FutureProvider.autoDispose<MonthlyDashboardSummary>((ref) async {
  final sales = await ref.watch(salesStateProvider.future);
  final finances = await ref.watch(financesStateProvider.future);
  final sessions = await ref.watch(productionSessionsStateProvider.future);
  final salaryState = await ref.watch(salaryStateProvider.future);
  
  final creditRepo = ref.watch(creditRepositoryProvider);
  final calculationService = ref.read(dashboardCalculationServiceProvider);
  final now = DateTime.now();
  final monthStart = calculationService.getMonthStart(now);

  // Fetch credit payments for the month
  final monthCreditPayments = await creditRepo.fetchPayments(startDate: monthStart);

  final metrics = calculationService.calculateMonthlyMetricsFromRecords(
    sales: sales.sales,
    creditPayments: monthCreditPayments,
    customers: [], // Not needed for primary KPIs here
    expenses: finances.expenses,
    salaryPayments: salaryState.monthlySalaryPayments,
    productionPayments: salaryState.productionPayments,
    sessions: sessions, // Now passing sessions for cost calculation
    referenceDate: now,
  );

  final monthTransactions = finances.expenses.where((e) => e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart)).toList();

  // Calculate separate credit recoveries and salary expenses for summary if needed
  final creditRecoveries = monthCreditPayments.fold<int>(0, (sum, p) => sum + p.amount);
  final salaryExpenses = salaryState.monthlySalaryPayments
      .where((p) => p.date.isAfter(monthStart) || p.date.isAtSameMomentAs(monthStart))
      .fold<int>(0, (sum, p) => sum + p.amount) +
      salaryState.productionPayments
      .where((p) => p.paymentDate.isAfter(monthStart) || p.paymentDate.isAtSameMomentAs(monthStart))
      .fold<int>(0, (sum, p) => sum + p.totalAmount);
      
  // Debug log for verification
  final sessionCosts = sessions
      .where((s) =>
          (s.date.isAfter(monthStart) || s.date.isAtSameMomentAs(monthStart)) &&
          s.status.name != 'cancelled') // strict check
      .fold<int>(0, (sum, s) => sum + (s.coutBobines ?? 0) + (s.coutElectricite ?? 0));

  final summary = MonthlyDashboardSummary(
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

  developer.log(
    'Dashboard Summary Updated: rev=${metrics.revenue}, coll=${metrics.collections} (incl. rec=$creditRecoveries), prod=${metrics.productionVolume}, exp=${metrics.expenses} (incl. sal=$salaryExpenses, sessCosts=$sessionCosts)',
    name: 'monthlyDashboardSummaryProvider',
  );

  return summary;
});
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

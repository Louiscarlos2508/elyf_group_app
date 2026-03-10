import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/salary_controller.dart' show SalaryState;
import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/clients_controller.dart' show ClientsState;
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/legacy_state_providers.dart' show clientsStateProvider;
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/customer_repository.dart' show CustomerSummary;
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/repository_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/service_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/dashboard_state_providers.dart' show dashboardCalculationServiceProvider;
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_credit.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/worker_monthly_stat.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/weekly_salary_info.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/customer_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/production_state_providers.dart'
    show
        productionSessionsInPeriodProvider;

export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_credit.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/worker_monthly_stat.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/weekly_salary_info.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';

/// Provider pour récupérer l'état des salaires.
final salaryStateProvider = FutureProvider.autoDispose<SalaryState>((ref) async {
  return ref.read(salaryControllerProvider).fetchSalaries();
});

/// Provider pour récupérer tous les ouvriers journaliers.
final allDailyWorkersProvider =
    FutureProvider.autoDispose<List<DailyWorker>>((ref) async {
  return ref.read(dailyWorkerRepositoryProvider).fetchAllWorkers();
});

/// Stream for Today's Credit Payments (Real-time)
final todayPaymentsStreamProvider =
    StreamProvider.autoDispose<List<CreditPayment>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  return ref.watch(creditRepositoryProvider).watchPayments(
        startDate: startOfDay,
        endDate: endOfDay,
      );
});

/// Stream for Monthly Credit Payments (Real-time).
final monthCreditPaymentsStreamProvider =
    StreamProvider.autoDispose<List<CreditPayment>>((ref) {
  final now = DateTime.now();
  final calculationService = ref.watch(dashboardCalculationServiceProvider);
  final monthStart = calculationService.getMonthStart(now);

  return ref.watch(creditRepositoryProvider).watchPayments(
        startDate: monthStart,
      );
});

final customerCreditsProvider =
    FutureProvider.autoDispose.family<List<Sale>, String>(
        (ref, customerId) async {
  // Keep alive for 3 minutes to prevent rapid rebuilds
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), link.close);
  ref.onDispose(timer.cancel);

  return ref.read(creditRepositoryProvider).fetchCustomerAllCredits(customerId);
});

final customerCreditHistoryProvider = FutureProvider.autoDispose
    .family<List<({Sale sale, List<CreditPayment> payments})>, String>((
  ref,
  customerId,
) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), link.close);
  ref.onDispose(timer.cancel);

  final creditRepo = ref.read(creditRepositoryProvider);
  final customerRepo = ref.read(customerRepositoryProvider);
  final saleRepo = ref.read(saleRepositoryProvider);

  // 1. Fetch ALL sales to ensure we get full history (no limit)
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
  final timer = Timer(const Duration(minutes: 3), link.close);
  ref.onDispose(timer.cancel);

  return ref.read(creditRepositoryProvider).fetchSalePayments(saleId);
});

final workerMonthlyStatsProvider =
    FutureProvider.autoDispose.family<List<WorkerMonthlyStat>, DateTime>((
  ref,
  month,
) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), link.close);
  ref.onDispose(timer.cancel);

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

final creditsDashboardProvider =
    FutureProvider.autoDispose<CreditsDashboardState>((ref) async {
  // Keep alive for 3 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 3), link.close);
  ref.onDispose(timer.cancel);

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

      final validCredits =
          credits.where((c) => c.remainingAmount > 0).toList();

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
  final mergedCustomers = <CustomerSummary>[...baseCustomers];
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
    final totalCreditFromCredits =
        credits.fold<int>(0, (sum, credit) => sum + credit.remainingAmount);
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

final weeklySalariesProvider = FutureProvider.autoDispose
    .family<List<WeeklySalaryInfo>, DateTime>((ref, selectedWeek) async {
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
          final workerName =
              worker?.name ?? 'Ouvrier inconnu ($workerId)';

          // CHECK IF THIS WORKER IS PAID FOR THIS DAY (by ID or by Name as fallback)
          final isPaidById =
              paidWorkerDayKeys.contains('id_${workerId}_${day.id}');
          final isPaidByName =
              paidWorkerDayKeys.contains('name_${workerName}_${day.id}');

          if (isPaidById || isPaidByName) {
            continue;
          }

          final tauxJour =
              worker?.salaireJournalier ?? day.salaireJournalierParPersonne;

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

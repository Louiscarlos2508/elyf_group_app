import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/repository_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/service_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/credit_state_providers.dart' show salaryStateProvider;
import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/sales_controller.dart' show SalesState;
import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/finances_controller.dart' show FinancesState;
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_record.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/controllers/salary_controller.dart' show SalaryState;
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/adapters/expense_balance_adapter.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/dashboard_calculation_service.dart';
import 'package:elyf_groupe_app/core/domain/entities/expense_balance_data.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';


export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_report_data.dart';

/// Provider pour récupérer le type de compteur configuré
// electricityMeterTypeProvider is defined in state_providers.dart (kept for backward compat)

/// Provider pour récupérer toutes les machines (sans filtre).
final allMachinesProvider = FutureProvider.autoDispose<List<Machine>>((
  ref,
) async {
  return ref.read(machineControllerProvider).fetchMachines();
});

final activityStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(activityControllerProvider).fetchTodaySummary(),
);

final salesStateProvider = StreamProvider.autoDispose<SalesState>(
  (ref) => ref.watch(salesControllerProvider).watchRecentSales(),
);

/// Provider pour le bilan des dépenses Eau Minérale.
final eauMineraleExpenseBalanceProvider =
    FutureProvider.autoDispose<List<ExpenseBalanceData>>((ref) async {
  final expenses =
      await ref.read(financesControllerProvider).fetchRecentExpenses();
  final adapter = EauMineraleExpenseBalanceAdapter();
  return adapter.convertToBalanceData(expenses.expenses);
});

/// Derived state for daily dashboard KPIs (Real-time).
/// Uses rxdart to stabilize emissions and avoid flickering.
final dailyDashboardSummaryProvider =
    StreamProvider.autoDispose<DailyDashboardMetrics>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  final salesStream = ref.watch(saleRepositoryProvider).watchSales(
        startDate: startOfDay,
        endDate: endOfDay,
      );
  final paymentsStream = ref.watch(eauMineraleCreditRepositoryProvider).watchPayments(
        startDate: startOfDay,
        endDate: endOfDay,
      );
  final sessionsStream =
      ref.watch(productionSessionRepositoryProvider).watchSessions(
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
    (List<Sale> sales, List<CreditPayment> payments,
        List<ProductionSession> sessions, List<ExpenseRecord> expenses,
        List<TreasuryOperation> operations) {
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
  final double production;
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
  final sessionsStream =
      ref.watch(productionSessionRepositoryProvider).watchSessions();
  final creditPaymentsStream = ref.watch(eauMineraleCreditRepositoryProvider).watchPayments(
        startDate: monthStart,
      );
  final treasuryStream = ref.watch(treasuryControllerProvider).watchOperations();

  // For salaryState, we use ref.watch and convert to stream to include it in combineLatest
  final salaryStream =
      Stream.fromFuture(ref.watch(salaryStateProvider.future));

  return Rx.combineLatest6(
    salesStream,
    financesStream,
    sessionsStream,
    salaryStream,
    creditPaymentsStream,
    treasuryStream,
    (List<Sale> sales, List<ExpenseRecord> expenses,
        List<ProductionSession> sessions,
        SalaryState salaryState,
        List<CreditPayment> creditPayments,
        List<TreasuryOperation> treasuryOperations) {
      return _calculateMonthlySummary(
        ref,
        SalesState(sales: sales),
        FinancesState(expenses: expenses),
        sessions,
        salaryState,
        creditPayments,
        treasuryOperations,
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
  List<TreasuryOperation> treasuryOperations,
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
    treasuryOperations: treasuryOperations,
    referenceDate: now,
  );

  final monthTransactions = finances.expenses
      .where(
        (e) =>
            e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart),
      )
      .toList();

  final creditRecoveries =
      creditPayments.fold<int>(0, (sum, p) => sum + p.amount);

  final salaryExpenses = salaryState.monthlySalaryPayments
          .where(
            (p) =>
                p.date.isAfter(monthStart) ||
                p.date.isAtSameMomentAs(monthStart),
          )
          .fold<int>(0, (sum, p) => sum + p.amount) +
      salaryState.productionPayments
          .where(
            (p) =>
                p.paymentDate.isAfter(monthStart) ||
                p.paymentDate.isAtSameMomentAs(monthStart),
          )
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/repository_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/service_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/expense_record.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/treasury_movement.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

import '../controllers/finances_controller.dart';

export 'package:elyf_groupe_app/features/eau_minerale/domain/entities/treasury_movement.dart';

final financesStateProvider = StreamProvider.autoDispose<FinancesState>(
  (ref) => ref.watch(financesControllerProvider).watchRecentExpenses(),
);

final treasuryHistoryProvider =
    StreamProvider.autoDispose<List<TreasuryMovement>>((ref) {
  final salesStream = ref
      .watch(salesControllerProvider)
      .watchRecentSales()
      .map((state) => state.sales);
  final paymentsStream =
      ref.watch(clientsControllerProvider).watchAllCreditPayments();
  final expensesStream = ref.watch(financesControllerProvider).watchExpenses();
  final manualOpsStream =
      ref.watch(treasuryControllerProvider).watchOperations();

  final mapper = ref.read(treasuryMovementMapperProvider);

  return Rx.combineLatest4(
    salesStream,
    paymentsStream,
    expensesStream,
    manualOpsStream,
    (List<Sale> sales, List<CreditPayment> payments,
        List<ExpenseRecord> expenses, List<TreasuryOperation> manualOps) {
      return mapper.mapToMovements(
        sales: sales,
        payments: payments,
        expenses: expenses,
        manualOps: manualOps,
      );
    },
  ).debounceTime(const Duration(milliseconds: 500));
});

final treasuryOperationsProvider =
    StreamProvider.autoDispose<List<TreasuryOperation>>(
  (ref) => ref.watch(treasuryControllerProvider).watchOperations(),
);

final treasuryBalancesProvider =
    StreamProvider.autoDispose<Map<String, int>>(
  (ref) => ref.watch(treasuryControllerProvider).watchBalances(),
);

/// Provider for Absolute Treasury Balances (Cumulative from all-time source data)
final absoluteTreasuryBalanceProvider =
    StreamProvider.autoDispose<Map<String, int>>((ref) {
  final salesStream = ref.watch(saleRepositoryProvider).watchSales();
  final paymentsStream = ref.watch(creditRepositoryProvider).watchPayments();
  final expensesStream = ref.watch(financeRepositoryProvider).watchExpenses();
  final manualOpsStream =
      ref.watch(treasuryControllerProvider).watchOperations();

  return Rx.combineLatest4(
    salesStream,
    paymentsStream,
    expensesStream,
    manualOpsStream,
    (List<Sale> sales, List<CreditPayment> payments,
        List<ExpenseRecord> expenses, List<TreasuryOperation> manualOps) {
      final calculationService = ref.read(dashboardCalculationServiceProvider);
      return calculationService.calculateCumulativeBalances(
        sales: sales,
        creditPayments: payments,
        expenses: expenses,
        treasuryOperations: manualOps,
      );
    },
  ).debounceTime(const Duration(milliseconds: 500));
});

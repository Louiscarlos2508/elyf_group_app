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
  final manualOpsStream =
      ref.watch(treasuryControllerProvider).watchOperations();

  final mapper = ref.read(treasuryMovementMapperProvider);

  return manualOpsStream.map((manualOps) {
    return mapper.mapToMovements(manualOps);
  }).debounceTime(const Duration(milliseconds: 500));
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
  final manualOpsStream =
      ref.watch(treasuryControllerProvider).watchOperations();

  return manualOpsStream.map((manualOps) {
    final calculationService = ref.read(dashboardCalculationServiceProvider);
    return calculationService.calculateCumulativeBalances(
      treasuryOperations: manualOps,
    );
  }).debounceTime(const Duration(milliseconds: 500));
});

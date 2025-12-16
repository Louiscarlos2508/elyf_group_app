import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/controllers/orange_money_controller.dart';
import '../data/repositories/mock_transaction_repository.dart';
import '../domain/repositories/transaction_repository.dart';

/// Provider for transaction repository.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => MockTransactionRepository(),
);

/// Provider for Orange Money controller.
final orangeMoneyControllerProvider = Provider<OrangeMoneyController>(
  (ref) => OrangeMoneyController(
    ref.watch(transactionRepositoryProvider),
  ),
);

/// Provider for Orange Money state.
final orangeMoneyStateProvider = FutureProvider.autoDispose<OrangeMoneyState>(
  (ref) async => ref.watch(orangeMoneyControllerProvider).fetchState(),
);


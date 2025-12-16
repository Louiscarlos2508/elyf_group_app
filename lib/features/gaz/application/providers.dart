import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/controllers/gas_controller.dart';
import '../data/repositories/mock_gas_repository.dart';
import '../domain/repositories/gas_repository.dart';

/// Provider for gas repository.
final gasRepositoryProvider = Provider<GasRepository>(
  (ref) => MockGasRepository(),
);

/// Provider for gas controller.
final gasControllerProvider = Provider<GasController>(
  (ref) => GasController(
    ref.watch(gasRepositoryProvider),
  ),
);

/// Provider for gas state.
final gasStateProvider = FutureProvider.autoDispose<GasState>(
  (ref) async => ref.watch(gasControllerProvider).fetchState(),
);


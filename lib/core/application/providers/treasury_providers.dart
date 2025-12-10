import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/controllers/treasury_controller.dart';
import '../../../core/data/repositories/mock_treasury_repository.dart';
import '../../../core/domain/entities/treasury.dart';
import '../../../core/domain/repositories/treasury_repository.dart';

/// Provider pour le repository de trésorerie.
final treasuryRepositoryProvider = Provider<TreasuryRepository>(
  (ref) => MockTreasuryRepository(),
);

/// Provider pour le controller de trésorerie.
final treasuryControllerProvider = Provider<TreasuryController>(
  (ref) => TreasuryController(ref.watch(treasuryRepositoryProvider)),
);

/// Provider pour récupérer la trésorerie d'un module.
final treasuryProvider = FutureProvider.autoDispose.family<Treasury, String>(
  (ref, moduleId) async {
    return ref.read(treasuryControllerProvider).fetchTreasury(moduleId);
  },
);


import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';

// Providers moved to dashboard_state_providers.dart or other specialized files
// but kept commented or removed if redundant.
// Removed: allMachinesProvider, activityStateProvider, salesStateProvider, financesStateProvider, eauMineraleExpenseBalanceProvider

// Removed duplicate: allDailyWorkersProvider

// Moved to specific providers

final clientsStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(clientsControllerProvider).fetchCustomers(),
);

// Moved

// Moved

// Moved to production_state_providers.dart

// Moved to specific providers

// Moved to production_state_providers.dart

// All providers either moved or redundant. 
// This file can eventually be deleted after ensuring no other module relies on it directly.

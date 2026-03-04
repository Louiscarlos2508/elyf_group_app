import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
import '../../audit_trail/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/repositories/repository_providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';
import '../data/repositories/treasury_offline_repository.dart';
import '../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../application/controllers/agents_controller.dart';
import '../application/controllers/commissions_controller.dart';
import '../application/controllers/liquidity_controller.dart';
import '../application/controllers/orange_money_controller.dart';
import '../application/controllers/settings_controller.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../data/repositories/agent_offline_repository.dart';
import '../data/repositories/commission_offline_repository.dart';
import '../data/repositories/liquidity_offline_repository.dart';
import '../data/repositories/settings_offline_repository.dart';
import '../data/repositories/transaction_offline_repository.dart';
import '../domain/entities/agent.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../domain/entities/commission.dart';
import '../domain/entities/liquidity_checkpoint.dart';
import '../domain/entities/transaction.dart';
import '../domain/repositories/agent_repository.dart';
import '../domain/repositories/commission_repository.dart';
import '../domain/repositories/liquidity_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import '../domain/services/commission_calculation_service.dart';
import '../domain/services/commission_service.dart';
import '../domain/services/transaction_validation_service.dart';
import '../domain/services/liquidity_service.dart';
import 'providers/permission_providers.dart';

/// Provider for CommissionCalculationService.
final commissionCalculationServiceProvider =
    Provider<CommissionCalculationService>(
      (ref) => CommissionCalculationService(),
    );

/// Provider for CommissionService (Hybrid Model).
final commissionServiceProvider = Provider<CommissionService>((ref) {
  return CommissionService(
    commissionRepository: ref.watch(commissionRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

/// Provider for TransactionValidationService.
final transactionValidationServiceProvider =
    Provider<TransactionValidationService>(
      (ref) => TransactionValidationService(),
    );

/// Provider for transaction repository.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final auditTrailRepository = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'system';

  return TransactionOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    auditTrailRepository: auditTrailRepository,
    userId: userId,
  );
});

/// Provider for Orange Money controller.
final orangeMoneyControllerProvider = Provider<OrangeMoneyController>(
  (ref) => OrangeMoneyController(
    ref.watch(transactionRepositoryProvider),
    ref.watch(liquidityRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(orangeMoneyTreasuryRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(currentUserIdProvider) ?? 'system',
    ref.watch(orangeMoneyPermissionAdapterProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
  ),
);

/// Provider for Orange Money state.
final orangeMoneyStateProvider = FutureProvider.autoDispose<OrangeMoneyState>(
  (ref) async => ref.watch(orangeMoneyControllerProvider).fetchState(),
);

/// Provider for filtered transactions list.
/// Key format: "searchQuery|type|startDate|endDate"
/// - searchQuery: text to search (name, phone, reference)
/// - type: TransactionType name or empty
/// - startDate: milliseconds since epoch or empty
/// - endDate: milliseconds since epoch or empty
final filteredTransactionsProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, key) {
      final parts = key.split('|');
      final searchQuery = parts.isNotEmpty && parts[0].isNotEmpty
          ? parts[0]
          : null;
      final typeStr = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      final type = typeStr != null
          ? TransactionType.values.firstWhere(
              (e) => e.name == typeStr,
              orElse: () => TransactionType.cashIn,
            )
          : null;
      final startDate = parts.length > 2 && parts[2].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2]))
          : null;
      final endDate = parts.length > 3 && parts[3].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3]))
          : null;

      final repository = ref.watch(transactionRepositoryProvider);

      // Récupérer les transactions avec filtres de base via un stream
      return repository.watchTransactions(
        startDate: startDate,
        endDate: endDate,
        type: type,
      ).map((transactions) {
        // Filtrer par recherche textuelle si fournie
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          return transactions.where((t) {
            final nameMatch =
                t.customerName?.toLowerCase().contains(query) ?? false;
            final phoneMatch = t.phoneNumber.toLowerCase().contains(query);
            final referenceMatch =
                t.reference?.toLowerCase().contains(query) ?? false;
            return nameMatch || phoneMatch || referenceMatch;
          }).toList();
        }
        return transactions;
      });
    });

/// Provider for agent repository.
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final auditTrailRepository = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'system';

  return AgentOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    auditTrailRepository: auditTrailRepository,
    userId: userId,
  );
});

/// Provider for agents controller.
final agentsControllerProvider = Provider<AgentsController>(
  (ref) => AgentsController(
    ref.watch(enterpriseRepositoryProvider),
    ref.watch(agentRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(orangeMoneyTreasuryRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(currentUserIdProvider) ?? 'system',
    ref.watch(orangeMoneyPermissionAdapterProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(tenantContextServiceProvider),
  ),
);

/// Provider for commission repository.
final commissionRepositoryProvider = Provider<CommissionRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final auditTrailRepository = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'system';

  return CommissionOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'orange_money',
    auditTrailRepository: auditTrailRepository,
    userId: userId,
  );
});

/// Provider for commissions controller.
final commissionsControllerProvider = Provider<CommissionsController>(
  (ref) => CommissionsController(
    ref.watch(commissionRepositoryProvider),
    ref.watch(orangeMoneyTreasuryRepositoryProvider),
    ref.watch(currentUserIdProvider) ?? 'system',
    ref.watch(orangeMoneyPermissionAdapterProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
  ),
);

/// Provider for settings repository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final auditTrailRepository = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'system';

  return SettingsOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'orange_money',
    auditTrailRepository: auditTrailRepository,
    userId: userId,
  );
});

/// Provider for settings controller.
final settingsControllerProvider = Provider<SettingsController>(
  (ref) => SettingsController(
    ref.watch(settingsRepositoryProvider),
    ref.watch(currentUserIdProvider) ?? 'system',
  ),
);

/// Scoped enterprise IDs for Orange Money module data access (Hierarchy support).
final orangeMoneyScopedEnterpriseIdsProvider = FutureProvider<List<String>>((
  ref,
) async {
  final activeEnterprise = await ref.watch(activeEnterpriseProvider.future);
  if (activeEnterprise == null) return [];

  final List<String> scopedIds = [activeEnterprise.id];

  // If hierarchy is supported/required for the active enterprise type
  if (activeEnterprise.type.canHaveChildren) {
    final allAccessibleEnterprises = await ref.watch(
      userAccessibleEnterprisesProvider.future,
    );
    final childrenIds = allAccessibleEnterprises
        .where(
          (e) =>
              e.parentEnterpriseId == activeEnterprise.id ||
              e.ancestorIds.contains(activeEnterprise.id),
        )
        .map((e) => e.id);
    scopedIds.addAll(childrenIds);
  }

  return scopedIds.toSet().toList();
});

/// Provider for Orange Money Treasury Repository.
final orangeMoneyTreasuryRepositoryProvider = Provider<OrangeMoneyTreasuryRepository>((ref) {
  final drift = ref.watch(driftServiceProvider);
  final sync = ref.watch(syncManagerProvider);
  return OrangeMoneyTreasuryOfflineRepository(drift.db, sync);
});

/// Provider for Orange Money Treasury Balances.
final orangeMoneyTreasuryBalanceProvider =
    StreamProvider.family<Map<String, int>, String>((ref, enterpriseId) {
      final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
      return repo.watchBalances(enterpriseId);
    });

/// Provider for Orange Money Treasury Operations Stream.
final orangeMoneyTreasuryOperationsStreamProvider =
    StreamProvider.family<List<TreasuryOperation>, String>((ref, enterpriseId) {
      final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
      return repo.watchOperations(enterpriseId);
    });

/// Provider for liquidity repository.
final liquidityRepositoryProvider = Provider<LiquidityRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final auditTrailRepository = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'system';

  return LiquidityOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'orange_money',
    auditTrailRepository: auditTrailRepository,
    userId: userId,
  );
});

/// Provider for liquidity service.
final liquidityServiceProvider = Provider<LiquidityService>((ref) {
  return LiquidityService(
    liquidityRepository: ref.watch(liquidityRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

/// Provider for liquidity controller.
final liquidityControllerProvider = Provider<LiquidityController>(
  (ref) => LiquidityController(
    ref.watch(liquidityRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(currentUserIdProvider) ?? 'system',
    ref.watch(orangeMoneyPermissionAdapterProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(liquidityServiceProvider),
  ),
);

/// Provider for agencies (locations) list with filters.
final agentAgenciesProvider = FutureProvider.autoDispose.family<List<Enterprise>, String>((
  ref,
  key,
) async {
  final parts = key.split('|');
  final parentEnterpriseId = parts[0].isEmpty ? null : parts[0];
  final searchQuery = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
  final excludeAssigned = parts.length > 3 && parts[3] == 'true';
  final includeAgencyId = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null;

  final controller = ref.watch(agentsControllerProvider);
  return await controller.fetchAgencies(
    parentEnterpriseId: parentEnterpriseId,
    searchQuery: searchQuery,
    excludeAssigned: excludeAssigned,
    includeAgencyId: includeAgencyId,
  );
});

/// Provider for agent accounts (SIMs) list with filters.
final agentAccountsProvider = FutureProvider.autoDispose.family<List<Agent>, String>((
  ref,
  key,
) async {
  final parts = key.split('|');
  final enterpriseId = parts[0].isEmpty ? null : parts[0];
  final searchQuery = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;

  final controller = ref.watch(agentsControllerProvider);
  return await controller.fetchAgents(
    enterpriseId: enterpriseId,
    searchQuery: searchQuery,
  );
});

/// Provider for agents daily statistics.
final agentsDailyStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
      final parts = key.split('|');
      final enterpriseId = parts[0].isEmpty ? null : parts[0];

      final controller = ref.watch(agentsControllerProvider);
      return await controller.getDailyStatistics(
        enterpriseId: enterpriseId,
        date: DateTime.now(),
      );
    });

/// Provider for commissions statistics.
final commissionsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
      final enterpriseId = key.isEmpty ? null : key;
      final controller = ref.watch(commissionsControllerProvider);
      return await controller.getStatistics(enterpriseId: enterpriseId);
    });

/// Provider for commissions list.
final commissionsProvider = FutureProvider.autoDispose
    .family<List<Commission>, String>((ref, key) async {
      final enterpriseId = key.isEmpty ? null : key;
      final controller = ref.watch(commissionsControllerProvider);
      return await controller.fetchCommissions(enterpriseId: enterpriseId);
    });

/// Provider for current month commission.
final currentMonthCommissionProvider = FutureProvider.autoDispose
    .family<Commission?, String>((ref, key) async {
      if (key.isEmpty) return null;
      final controller = ref.watch(commissionsControllerProvider);
      return await controller.getCurrentMonthCommission(key);
    });

/// Provider for agency commissions (network-wide).
/// Key format: "period|status"
final agencyCommissionsProvider = FutureProvider.autoDispose
    .family<List<Commission>, String>((ref, key) async {
      final parts = key.split('|');
      final period = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
      final statusStr = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      final status = statusStr != null ? CommissionStatus.values.byName(statusStr) : null;
      
      final controller = ref.watch(commissionsControllerProvider);
      return await controller.fetchNetworkCommissions(period: period, status: status);
    });

/// Provider for agency commission statistics (network-wide).
/// Key: period string (YYYY-MM)
final agencyCommissionsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, period) async {
      final controller = ref.watch(commissionsControllerProvider);
      return await controller.getNetworkStatistics(period: period.isEmpty ? null : period);
    });

/// Provider for mapping network enterprise IDs to their names.
final networkEnterprisesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  try {
    // Import enterprisesProvider from administration
    // Note: We need to import it or use a proxy. 
    // Since providers.dart for orange_money already imports administration entities, 
    // we should be able to watch enterprisesProvider if it's exported or visible.
    // Based on earlier inspection, it's in lib/features/administration/application/providers.dart
    
    final enterprises = await ref.watch(enterprisesProvider.future);
    return {for (var e in enterprises) e.id: e.name};
  } catch (e) {
    AppLogger.error('Error in networkEnterprisesProvider', error: e);
    return {};
  }
});

/// Provider for reports statistics with date range.
final reportsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
      // Key format: "startDate|endDate" where dates are in milliseconds since epoch
      final parts = key.split('|');
      final startDate = parts.isNotEmpty && parts[0].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0]))
          : null;
      final endDate = parts.length > 1 && parts[1].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]))
          : null;

      final controller = ref.watch(orangeMoneyControllerProvider);
      return await controller.getStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    });

/// Provider for today's liquidity checkpoint.
final todayLiquidityCheckpointProvider = FutureProvider.autoDispose
    .family<LiquidityCheckpoint?, String>((ref, key) async {
      if (key.isEmpty) return null;
      final controller = ref.watch(liquidityControllerProvider);
      return await controller.getTodayCheckpoint(key);
    });

/// Provider for all agent-related treasury operations (recharges/withdrawals).
final allAgentRechargesProvider = StreamProvider.autoDispose.family<List<TreasuryOperation>, String>((ref, enterpriseId) {
  final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
  return repo.watchOperations(
    enterpriseId,
    referenceEntityType: 'agent_account',
  );
});

/// Provider for transactions of a specific agent.
final agentTransactionsProvider = StreamProvider.autoDispose.family<List<Transaction>, String>((ref, agentId) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactionsByAgent(agentId);
});

/// Provider for treasury history (recharges/withdrawals) of a specific agent.
final agentTreasuryHistoryProvider = StreamProvider.autoDispose.family<List<TreasuryOperation>, String>((ref, agentId) {
  final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  return repo.watchOperations(
    activeEnterprise?.id ?? 'default',
    referenceEntityId: agentId,
    referenceEntityType: 'agent_account',
  );
});

/// Provider for aggregated statistics of a specific agent.
final agentStatisticsProvider = Provider.autoDispose.family<AsyncValue<Map<String, dynamic>>, String>((ref, agentId) {
  final transactionsAsync = ref.watch(agentTransactionsProvider(agentId));
  final treasuryAsync = ref.watch(agentTreasuryHistoryProvider(agentId));

  return transactionsAsync.when(
    data: (transactions) {
      return treasuryAsync.when(
        data: (treasuryOps) {
          int totalRecharged = 0;
          int totalWithdrawn = 0;
          int totalCommission = 0;
          int totalCashIn = 0;
          int totalCashOut = 0;

          // Process Treasury Ops (Recharges/Withdrawals)
          for (final op in treasuryOps) {
            if (op.fromAccount == PaymentMethod.cash) {
              totalRecharged += op.amount;
            } else if (op.toAccount == PaymentMethod.cash) {
              totalWithdrawn += op.amount;
            }
          }

          // Process Transactions
          for (final t in transactions) {
            if (t.status != TransactionStatus.completed) continue;
            totalCommission += t.commission ?? 0;
            if (t.type == TransactionType.cashIn) {
              totalCashIn += t.amount;
            } else if (t.type == TransactionType.cashOut) {
              totalCashOut += t.amount;
            }
          }

          return AsyncValue.data({
            'totalRecharged': totalRecharged,
            'totalWithdrawn': totalWithdrawn,
            'totalCommission': totalCommission,
            'totalCashIn': totalCashIn,
            'totalCashOut': totalCashOut,
            'transactionCount': transactions.where((t) => t.isCompleted).length,
          });
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Provider for liquidity checkpoints list.
final liquidityCheckpointsProvider = FutureProvider.autoDispose
    .family<List<LiquidityCheckpoint>, String>((ref, key) async {
      // Key format: "enterpriseId|startDate|endDate" where dates are in milliseconds
      final parts = key.split('|');
      final enterpriseId = parts.isNotEmpty && parts[0].isNotEmpty
          ? parts[0]
          : null;
      final startDate = parts.length > 1 && parts[1].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]))
          : null;
      final endDate = parts.length > 2 && parts[2].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2]))
          : null;

      final controller = ref.watch(liquidityControllerProvider);
      return await controller.fetchCheckpoints(
        enterpriseId: enterpriseId,
        startDate: startDate,
        endDate: endDate,
      );
    });

/// Provider for daily transaction statistics.
/// Key format: "enterpriseId|date" where date is in milliseconds since epoch
/// Provider pour les statistiques quotidiennes de transactions/dépôts-retraits.
/// Détecte automatiquement si l'utilisateur utilise le module Agents ou Transactions.
/// Algorithme robuste: utilise watchTransactions pour la réactivité en temps réel.
final dailyTransactionStatsProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) {
      final parts = key.split('|');
      final enterpriseId = parts.isNotEmpty && parts[0].isNotEmpty
          ? parts[0]
          : null;
      final date = parts.length > 1 && parts[1].isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]))
          : DateTime.now();

      final normalizedDate = DateTime(date.year, date.month, date.day);
      final startOfDay = normalizedDate;
      final endOfDay = normalizedDate
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      // Stratégie réactive: On regarde si on est en vue réseau (Hierarchy)
      final scopedIdsAsync = ref.watch(orangeMoneyScopedEnterpriseIdsProvider);
      final repository = ref.watch(transactionRepositoryProvider);

      return scopedIdsAsync.when(
        data: (ids) {
          final stream = (ids.length > 1)
              ? repository.watchTransactionsByEnterprises(
                  ids,
                  startDate: startOfDay,
                  endDate: endOfDay,
                )
              : repository.watchTransactions(
                  startDate: startOfDay,
                  endDate: endOfDay,
                );

          return stream.map((transactions) {
            int deposits = 0;
            int withdrawals = 0;
            for (final t in transactions) {
              if (t.status != TransactionStatus.completed) continue;
              
              if (t.type == TransactionType.cashIn) {
                deposits += t.amount;
              } else if (t.type == TransactionType.cashOut) {
                withdrawals += t.amount;
              }
            }

            return {
              'deposits': deposits,
              'withdrawals': withdrawals,
              'transactionCount': transactions.length,
              'source': ids.length > 1 ? 'network' : 'single',
            };
          });
        },
        loading: () => Stream.value({
          'deposits': 0,
          'withdrawals': 0,
          'transactionCount': 0,
          'source': 'loading',
        }),
        error: (e, __) => Stream.value({
          'deposits': 0,
          'withdrawals': 0,
          'transactionCount': 0,
          'source': 'error',
        }),
      );
    });


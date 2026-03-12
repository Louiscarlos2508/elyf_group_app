import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
import '../../audit_trail/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../data/repositories/treasury_offline_repository.dart';
import '../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';


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
  final userId = ref.watch(currentUserIdProvider);

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
    ref.watch(commissionRepositoryProvider),
    ref.watch(orangeMoneyTreasuryRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(currentUserIdProvider),
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
  final userId = ref.watch(currentUserIdProvider);

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
    ref.watch(orangeMoneyTreasuryRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(currentUserIdProvider),
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
  final userId = ref.watch(currentUserIdProvider);

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
    ref.watch(currentUserIdProvider),
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
  final userId = ref.watch(currentUserIdProvider);

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
    ref.watch(currentUserIdProvider),
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
  final userId = ref.watch(currentUserIdProvider);

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
    ref.watch(currentUserIdProvider),
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
  return controller.fetchAgencies(
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
  return controller.fetchAgents(
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
      return controller.getDailyStatistics(
        enterpriseId: enterpriseId,
        date: DateTime.now(),
      );
    });

/// Provider for commissions statistics.
final commissionsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
      final enterpriseId = key.isEmpty ? null : key;
      final controller = ref.watch(commissionsControllerProvider);
      return controller.getStatistics(enterpriseId: enterpriseId);
    });

/// Provider for commissions list.
final commissionsProvider = FutureProvider.autoDispose
    .family<List<Commission>, String>((ref, key) async {
      final enterpriseId = key.isEmpty ? null : key;
      final controller = ref.watch(commissionsControllerProvider);
      return controller.fetchCommissions(enterpriseId: enterpriseId);
    });

/// Provider for current month commission.
final currentMonthCommissionProvider = FutureProvider.autoDispose
    .family<Commission?, String>((ref, key) async {
      if (key.isEmpty) return null;
      final controller = ref.watch(commissionsControllerProvider);
      return controller.getCurrentMonthCommission(key);
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
      return controller.fetchNetworkCommissions(period: period, status: status);
    });

/// Provider for agency commission statistics (network-wide).
/// Key: period string (YYYY-MM)
final agencyCommissionsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, period) async {
      final controller = ref.watch(commissionsControllerProvider);
      return controller.getNetworkStatistics(period: period.isEmpty ? null : period);
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
      return controller.getStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    });

/// Provider for today's liquidity checkpoint.
final todayLiquidityCheckpointProvider = FutureProvider.autoDispose
    .family<LiquidityCheckpoint?, String>((ref, key) async {
      if (key.isEmpty) return null;
      final controller = ref.watch(liquidityControllerProvider);
      return controller.getTodayCheckpoint(key);
    });

/// Provider for all agent-related treasury operations (recharges/withdrawals).
final allAgentRechargesProvider = StreamProvider.autoDispose.family<List<TreasuryOperation>, String>((ref, key) {
  final parts = key.split('|');
  final enterpriseId = parts[0];
  final startDate = parts.length > 1 ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])) : null;
  final endDate = parts.length > 2 ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])) : null;

  final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
  return repo.watchOperations(
    enterpriseId,
    referenceEntityType: 'agent_account',
    from: startDate,
    to: endDate,
  );
});

/// Provider for transactions of a specific agent.
final agentTransactionsProvider = StreamProvider.autoDispose.family<List<Transaction>, String>((ref, key) {
  final parts = key.split('|');
  final agentId = parts[0];
  final startDate = parts.length > 1 ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])) : null;
  final endDate = parts.length > 2 ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])) : null;

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactionsByAgent(agentId, startDate: startDate, endDate: endDate);
});

/// Provider for treasury history (recharges/withdrawals) of a specific agent.
final agentTreasuryHistoryProvider = StreamProvider.autoDispose.family<List<TreasuryOperation>, String>((ref, key) {
  final parts = key.split('|');
  final agentId = parts[0];
  
  // Safe date parsing
  final startDate = (parts.length > 1 && parts[1].isNotEmpty) 
      ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])) 
      : null;
  final endDate = (parts.length > 2 && parts[2].isNotEmpty) 
      ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])) 
      : null;

  final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  
  return repo.watchOperations(
    activeEnterprise?.id ?? 'default',
    referenceEntityId: agentId,
    referenceEntityType: 'agent_account',
    from: startDate,
    to: endDate,
  );
});

/// Provider for aggregated statistics of a specific agent.
final agentStatisticsProvider = Provider.autoDispose.family<AsyncValue<Map<String, dynamic>>, String>((ref, key) {
  final parts = key.split('|');
  final agentId = parts[0];
  final startDateStr = parts.length > 1 ? parts[1] : '';
  final endDateStr = parts.length > 2 ? parts[2] : '';

  // Use the history provider to get the operations
  final historyKey = '$agentId|$startDateStr|$endDateStr';
  final transactionsAsync = ref.watch(agentTransactionsProvider(historyKey));
  final treasuryAsync = ref.watch(agentTreasuryHistoryProvider(historyKey));

  return transactionsAsync.when(
    data: (transactions) {
      return treasuryAsync.when(
        data: (treasuryOps) {
          int totalRecharged = 0;
          int totalWithdrawn = 0;
          int totalCommission = 0;

          // Process Treasury Ops (Agent Recharges/Withdrawals)
          // Perspective: Agency's Treasury
          for (final op in treasuryOps) {
            final reason = op.reason?.toLowerCase() ?? '';
            final isRechargeStr = reason.contains('recharge') || reason.contains('approvisionnement');
            final isRetraitStr = reason.contains('retrait');

            // 1. Check by keywords (Preferred)
            if (isRechargeStr) {
              totalRecharged += op.amount.toInt();
            } else if (isRetraitStr) {
              totalWithdrawn += op.amount.toInt();
            } 
            // 2. Fallback to accounts mapping
            else {
              // Recharge (Agency gives Float, gets Cash)
              if (op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash) {
                totalRecharged += op.amount.toInt();
              } 
              // Withdrawal (Agency gives Cash, gets Float)
              else if (op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney) {
                totalWithdrawn += op.amount.toInt();
              }
            }
          }

          // NB: Les transactions clients ne sont PAS incluses ici.
          // Les agents n'ont pas l'app, donc on ne peut pas connaitre leurs transactions
          // clients. Seules les recharges/retraits internes (TreasuryOperations)
          // avec l'entreprise mère sont comptabilisées.
          for (final t in transactions) {
            if (t.isCompleted) {
              totalCommission += (t.commission ?? 0).toInt();
            }
          }

          return AsyncValue.data({
            'totalRecharged': totalRecharged,
            'totalWithdrawn': totalWithdrawn,
            'totalCommission': totalCommission,
            // Aliases for UI compatibility (AgentNetworkCard uses totalCashIn/totalCashOut)
            'totalCashIn': totalRecharged, 
            'totalCashOut': totalWithdrawn,
            'deposits': totalRecharged,
            'withdrawals': totalWithdrawn,
            'transactionCount': treasuryOps.length,
            'clientTransactionCount': 0, // Agents n'ont pas l'app
            'treasuryCount': treasuryOps.length,
            'totalVolume': totalRecharged + totalWithdrawn,
            'source': 'agent_treasury_only',
          });
        },
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
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
      return controller.fetchCheckpoints(
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

      final scopedIdsAsync = ref.watch(orangeMoneyScopedEnterpriseIdsProvider);
      final transactionRepo = ref.watch(transactionRepositoryProvider);
      final treasuryRepo = ref.watch(orangeMoneyTreasuryRepositoryProvider);

      return scopedIdsAsync.when(
        data: (ids) {
          // 1. Stream de Transactions (Client)
          final transactionsStream = (ids.length > 1)
              ? transactionRepo.watchTransactionsByEnterprises(
                  ids,
                  startDate: startOfDay,
                  endDate: endOfDay,
                )
              : transactionRepo.watchTransactions(
                  startDate: startOfDay,
                  endDate: endOfDay,
                );

          // 2. Stream de TreasuryOperations (Agents + Internal)
          // On regarde les opérations pour l'entreprise mère et potentiellement les sous-agences si c'est une vue réseau
          final treasuryStream = treasuryRepo.watchOperations(
            enterpriseId ?? 'default',
            from: startOfDay,
            to: endOfDay,
            enterpriseIds: ids.length > 1 ? ids : null,
          );

          // 3. Combinaison des deux flux
          return Rx.combineLatest2(transactionsStream, treasuryStream, (transactions, treasuryOps) {
            int deposits = 0;
            int withdrawals = 0;
            int clientCount = 0;
            int treasuryCount = 0;

            // Clients Transactions
            for (final t in transactions) {
              if (t.status != TransactionStatus.completed) continue;
              clientCount++;
              if (t.type == TransactionType.cashIn) {
                deposits += t.amount;
              } else if (t.type == TransactionType.cashOut) {
                withdrawals += t.amount;
              }
            }

            // Treasury Operations (Agent Recharges / Agency Supply)
            for (final op in treasuryOps) {
              final reason = op.reason?.toLowerCase() ?? '';
              final isRechargeStr = reason.contains('recharge') || reason.contains('approvisionnement');
              final isRetraitStr = reason.contains('retrait');

              // Aggregation logic (same as AgentsController)
              if (isRechargeStr || op.type == TreasuryOperationType.supply) {
                deposits += op.amount;
                treasuryCount++;
              } else if (isRetraitStr || op.type == TreasuryOperationType.removal) {
                withdrawals += op.amount;
                treasuryCount++;
              } else if (op.type == TreasuryOperationType.transfer && op.referenceEntityType == 'agent_account') {
                if (op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash) {
                  deposits += op.amount;
                  treasuryCount++;
                } else if (op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney) {
                  withdrawals += op.amount;
                  treasuryCount++;
                }
              }
            }

            return {
              'deposits': deposits,
              'withdrawals': withdrawals,
              'transactionCount': clientCount + treasuryCount,
              'clientCount': clientCount,
              'treasuryCount': treasuryCount,
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

/// Provider for agent performance ranking.
/// Fetches all agents and calculates their flux to return a ranked list.
/// Uses a bulk-fetch strategy for performance and reliability.
final agentPerformanceRankingProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, key) {
  final parts = key.split('|');
  final enterpriseId = parts[0].isEmpty ? null : parts[0];
  final searchQuery = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  
  // Safe date parsing
  final startDate = (parts.length > 2 && parts[2].isNotEmpty) 
      ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])) 
      : null;
  final endDate = (parts.length > 3 && parts[3].isNotEmpty) 
      ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3])) 
      : null;

  final controller = ref.watch(agentsControllerProvider);
  final repo = ref.watch(orangeMoneyTreasuryRepositoryProvider);
  final activeEnterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';

  // 1. Fetch all agents first (Future inside StreamProvider)
  final agentsFuture = controller.fetchAgents(
    enterpriseId: enterpriseId,
    searchQuery: searchQuery,
  );

  // 2. Watch ALL treasury operations for this period that belong to agents
  final opsStream = repo.watchOperations(
    activeEnterpriseId,
    from: startDate,
    to: endDate,
    referenceEntityType: 'agent_account',
  );

  return opsStream.asyncMap((ops) async {
    final agents = await agentsFuture;
    final List<Map<String, dynamic>> ranking = [];

    // Grouping operations by agent
    final opsByAgent = <String, List<TreasuryOperation>>{};
    for (final op in ops) {
      if (op.referenceEntityId != null) {
        opsByAgent.putIfAbsent(op.referenceEntityId!, () => []).add(op);
      }
    }

    for (final agent in agents) {
      final agentOps = opsByAgent[agent.id] ?? [];
      int totalCashIn = 0;
      int totalCashOut = 0;

      for (final op in agentOps) {
        final reason = op.reason?.toLowerCase() ?? '';
        final isRechargeStr = reason.contains('recharge') || reason.contains('approvisionnement');
        final isRetraitStr = reason.contains('retrait');

        if (isRechargeStr) {
          totalCashIn += op.amount;
        } else if (isRetraitStr) {
          totalCashOut += op.amount;
        } else {
          // Fallback mapping
          if (op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash) {
            totalCashIn += op.amount;
          } else if (op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney) {
            totalCashOut += op.amount;
          }
        }
      }

      ranking.add({
        'agent': agent,
        'totalVolume': totalCashIn + totalCashOut,
        'count': agentOps.length,
        'deposits': totalCashIn,
        'withdrawals': totalCashOut,
        // Mock stats for UI consistency if needed
        'stats': {
          'totalCashIn': totalCashIn,
          'totalCashOut': totalCashOut,
          'transactionCount': agentOps.length,
        }
      });
    }

    // Sort by totalVolume descending
    ranking.sort((a, b) => (b['totalVolume'] as int).compareTo(a['totalVolume'] as int));
    return ranking;
  });
});


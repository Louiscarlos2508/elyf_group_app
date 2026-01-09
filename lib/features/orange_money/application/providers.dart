import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/controllers/agents_controller.dart';
import '../application/controllers/commissions_controller.dart';
import '../application/controllers/liquidity_controller.dart';
import '../application/controllers/orange_money_controller.dart';
import '../application/controllers/settings_controller.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../data/repositories/agent_offline_repository.dart';
import '../data/repositories/mock_commission_repository.dart';
import '../data/repositories/mock_liquidity_repository.dart';
import '../data/repositories/mock_settings_repository.dart';
import '../data/repositories/transaction_offline_repository.dart';
import '../domain/entities/agent.dart';
import '../domain/entities/commission.dart';
import '../domain/entities/liquidity_checkpoint.dart';
import '../domain/entities/transaction.dart';
import '../domain/repositories/agent_repository.dart';
import '../domain/repositories/commission_repository.dart';
import '../domain/repositories/liquidity_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/transaction_repository.dart';

/// Provider for transaction repository.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return TransactionOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
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

/// Provider for filtered transactions list.
/// Key format: "searchQuery|type|startDate|endDate"
/// - searchQuery: text to search (name, phone, reference)
/// - type: TransactionType name or empty
/// - startDate: milliseconds since epoch or empty
/// - endDate: milliseconds since epoch or empty
final filteredTransactionsProvider = FutureProvider.autoDispose
    .family<List<Transaction>, String>(
  (ref, key) async {
    final parts = key.split('|');
    final searchQuery = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
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

    final controller = ref.watch(orangeMoneyControllerProvider);
    final repository = ref.watch(transactionRepositoryProvider);

    // Récupérer les transactions avec filtres de base
    var transactions = await repository.fetchTransactions(
      startDate: startDate,
      endDate: endDate,
      type: type,
    );

    // Filtrer par recherche textuelle si fournie
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      transactions = transactions.where((t) {
        final nameMatch = t.customerName?.toLowerCase().contains(query) ?? false;
        final phoneMatch = t.phoneNumber.toLowerCase().contains(query);
        final referenceMatch = t.reference?.toLowerCase().contains(query) ?? false;
        return nameMatch || phoneMatch || referenceMatch;
      }).toList();
    }

    return transactions;
  },
);

/// Provider for agent repository.
final agentRepositoryProvider = Provider<AgentRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return AgentOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

/// Provider for agents controller.
final agentsControllerProvider = Provider<AgentsController>(
  (ref) => AgentsController(ref.watch(agentRepositoryProvider)),
);

/// Provider for commission repository.
final commissionRepositoryProvider = Provider<CommissionRepository>(
  (ref) => MockCommissionRepository(),
);

/// Provider for commissions controller.
final commissionsControllerProvider = Provider<CommissionsController>(
  (ref) => CommissionsController(ref.watch(commissionRepositoryProvider)),
);

/// Provider for settings repository.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => MockSettingsRepository(),
);

/// Provider for settings controller.
final settingsControllerProvider = Provider<SettingsController>(
  (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

/// Provider for liquidity repository.
final liquidityRepositoryProvider = Provider<LiquidityRepository>(
  (ref) => MockLiquidityRepository(),
);

/// Provider for liquidity controller.
final liquidityControllerProvider = Provider<LiquidityController>(
  (ref) => LiquidityController(ref.watch(liquidityRepositoryProvider)),
);

/// Provider for agents list with filters.
final agentsProvider = FutureProvider.autoDispose.family<List<Agent>, String>(
  (ref, key) async {
    final parts = key.split('|');
    final enterpriseId = parts[0].isEmpty ? null : parts[0];
    final statusStr = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    final status = statusStr != null ? AgentStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => AgentStatus.active,
    ) : null;
    final searchQuery = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
    
    final controller = ref.watch(agentsControllerProvider);
    return await controller.fetchAgents(
      enterpriseId: enterpriseId,
      status: status,
      searchQuery: searchQuery,
    );
  },
);

/// Provider for agents daily statistics.
final agentsDailyStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
  (ref, key) async {
    final parts = key.split('|');
    final enterpriseId = parts[0].isEmpty ? null : parts[0];
    
    final controller = ref.watch(agentsControllerProvider);
    return await controller.getDailyStatistics(
      enterpriseId: enterpriseId,
      date: DateTime.now(),
    );
  },
);

/// Provider for commissions statistics.
final commissionsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
  (ref, key) async {
    final enterpriseId = key.isEmpty ? null : key;
    final controller = ref.watch(commissionsControllerProvider);
    return await controller.getStatistics(enterpriseId: enterpriseId);
  },
);

/// Provider for commissions list.
final commissionsProvider = FutureProvider.autoDispose
    .family<List<Commission>, String>(
  (ref, key) async {
    final enterpriseId = key.isEmpty ? null : key;
    final controller = ref.watch(commissionsControllerProvider);
    return await controller.fetchCommissions(enterpriseId: enterpriseId);
  },
);

/// Provider for current month commission.
final currentMonthCommissionProvider = FutureProvider.autoDispose
    .family<Commission?, String>(
  (ref, key) async {
    if (key.isEmpty) return null;
    final controller = ref.watch(commissionsControllerProvider);
    return await controller.getCurrentMonthCommission(key);
  },
);

/// Provider for reports statistics with date range.
final reportsStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
  (ref, key) async {
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
  },
);

/// Provider for today's liquidity checkpoint.
final todayLiquidityCheckpointProvider = FutureProvider.autoDispose
    .family<LiquidityCheckpoint?, String>(
  (ref, key) async {
    if (key.isEmpty) return null;
    final controller = ref.watch(liquidityControllerProvider);
    return await controller.getTodayCheckpoint(key);
  },
);

/// Provider for liquidity checkpoints list.
final liquidityCheckpointsProvider = FutureProvider.autoDispose
    .family<List<LiquidityCheckpoint>, String>(
  (ref, key) async {
    // Key format: "enterpriseId|startDate|endDate" where dates are in milliseconds
    final parts = key.split('|');
    final enterpriseId = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
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
  },
);

/// Provider for daily transaction statistics.
/// Key format: "enterpriseId|date" where date is in milliseconds since epoch
/// Provider pour les statistiques quotidiennes de transactions/dépôts-retraits.
/// Détecte automatiquement si l'utilisateur utilise le module Agents ou Transactions.
/// Algorithme robuste: essaie d'abord Agents, puis Transactions si Agents n'est pas disponible.
final dailyTransactionStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
  (ref, key) async {
    final parts = key.split('|');
    final enterpriseId = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
    final date = parts.length > 1 && parts[1].isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]))
        : DateTime.now();
    
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final startOfDay = normalizedDate;
    final endOfDay = normalizedDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    
    // Stratégie robuste: Essayer d'abord le module Agents Affiliés
    // Vérifier si des agents existent pour cette entreprise
    try {
      final agentsController = ref.watch(agentsControllerProvider);
      final agents = await agentsController.fetchAgents(enterpriseId: enterpriseId);
      
      // Si des agents existent, utiliser les stats des agents
      if (agents.isNotEmpty) {
        final agentsStats = await agentsController.getDailyStatistics(
          enterpriseId: enterpriseId,
          date: normalizedDate,
        );
        
        // Extraire recharges et retraits (compatibilité avec différentes clés possibles)
        final deposits = agentsStats['recharges'] as int? ?? 
                        agentsStats['rechargesToday'] as int? ?? 0;
        final withdrawals = agentsStats['retraits'] as int? ?? 
                           agentsStats['withdrawalsToday'] as int? ?? 0;
        final transactionCount = agentsStats['transactionCount'] as int? ?? 0;
        
        return {
          'deposits': deposits,
          'withdrawals': withdrawals,
          'transactionCount': transactionCount,
          'source': 'agents',
        };
      }
    } catch (e) {
      // Si erreur avec agents, continuer avec transactions (silencieux, normal si module non disponible)
    }
    
    // Fallback: Utiliser le module Transactions
    try {
      final repository = ref.watch(transactionRepositoryProvider);
      final transactions = await repository.fetchTransactions(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      int deposits = 0;
      int withdrawals = 0;
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.cashIn && transaction.isCompleted) {
          deposits += transaction.amount;
        } else if (transaction.type == TransactionType.cashOut && transaction.isCompleted) {
          withdrawals += transaction.amount;
        }
      }
      
      return {
        'deposits': deposits,
        'withdrawals': withdrawals,
        'transactionCount': transactions.length,
        'source': 'transactions',
      };
    } catch (e) {
      // Si erreur avec transactions aussi, retourner des valeurs par défaut
      return {
        'deposits': 0,
        'withdrawals': 0,
        'transactionCount': 0,
        'source': 'none',
      };
    }
  },
);


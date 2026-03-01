import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_enterprise_extensions.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/adapters/orange_money_permission_adapter.dart';

/// Controller for managing mobile money agents (represented as enterprises).
class AgentsController {
  AgentsController(
    this._enterpriseRepository,
    this._agentRepository,
    this._transactionRepository,
    this._auditTrailService,
    this.userId,
    this._permissionAdapter,
    this._activeEnterpriseId,
  );

  final EnterpriseRepository _enterpriseRepository;
  final AgentRepository _agentRepository;
  final TransactionRepository _transactionRepository;
  final AuditTrailService _auditTrailService;
  final String userId;
  final OrangeMoneyPermissionAdapter _permissionAdapter;
  final String _activeEnterpriseId;

  // --- Agency (Enterprise) Management ---

  /// Fetches enterprises that are mobile money agencies (Kiosks, Boutiques).
  Future<List<Enterprise>> fetchAgencies({
    String? parentEnterpriseId,
    String? searchQuery,
    bool excludeAssigned = false,
  }) async {
    final List<String> targetIds;

    if (parentEnterpriseId != null) {
      targetIds = [parentEnterpriseId];
    } else {
      final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
      targetIds = accessibleIds.toList();
    }

    final allEnterprises = await _enterpriseRepository.getAllEnterprises();
    
    var agencies = allEnterprises.where((e) {
      final isAccessible = targetIds.contains(e.parentEnterpriseId) || targetIds.contains(e.id);
      final isMobileMoney = e.isMobileMoney;
      // Filter out self unless searching specifically
      final isNotActiveSelf = e.id != _activeEnterpriseId;
      
      return isAccessible && isMobileMoney && isNotActiveSelf;
    }).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      agencies = agencies.where((a) {
        return a.name.toLowerCase().contains(query);
      }).toList();
    }

    if (excludeAssigned) {
      final allAgents = await _agentRepository.fetchAgents(
        enterpriseId: _activeEnterpriseId,
      );
      final assignedAgencyIds = allAgents.map((a) => a.enterpriseId).toSet();
      agencies = agencies.where((a) => !assignedAgencyIds.contains(a.id)).toList();
    }

    return agencies;
  }

  Future<Enterprise?> getAgency(String agencyId) async {
    return await _enterpriseRepository.getEnterpriseById(agencyId);
  }

  Future<void> createAgency(Enterprise agency) async {
    await _enterpriseRepository.createEnterprise(agency);
    _logAgentEvent(agency.id, 'CREATE_AGENCY', 'Agency: ${agency.name}', 'agency');
  }

  Future<void> updateAgency(Enterprise agency) async {
    await _enterpriseRepository.updateEnterprise(agency);
    _logAgentEvent(agency.id, 'UPDATE_AGENCY', 'Agency: ${agency.name}', 'agency');
  }

  Future<void> deleteAgency(String agencyId) async {
    final agency = await getAgency(agencyId);
    if (agency != null) {
      await _enterpriseRepository.deleteEnterprise(agencyId);
      _logAgentEvent(agencyId, 'DELETE_AGENCY', 'Agency ID: $agencyId', 'agency');
    }
  }

  Stream<List<Enterprise>> watchAgencies({String? parentEnterpriseId}) {
    return _enterpriseRepository.watchAllEnterprises().map((list) {
      return list.where((e) {
        final isMobileMoney = e.isMobileMoney;
        final isChild = parentEnterpriseId != null ? e.parentEnterpriseId == parentEnterpriseId : e.id != _activeEnterpriseId;
        return isMobileMoney && isChild;
      }).toList();
    });
  }

  // --- Agent (Transaction Account) Management ---

  /// Fetches agents (SIMs/Accounts).
  Future<List<Agent>> fetchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  }) async {
    return await _agentRepository.fetchAgents(
      enterpriseId: enterpriseId ?? _activeEnterpriseId,
      status: status,
      searchQuery: searchQuery,
    );
  }

  Future<Agent?> getAgent(String agentId) async {
    return await _agentRepository.getAgent(agentId);
  }

  Future<void> createAgent(Agent agent) async {
    await _agentRepository.createAgent(agent);
    _logAgentEvent(agent.id, 'CREATE_AGENT_ACCOUNT', 'Agent: ${agent.name}, SIM: ${agent.simNumber}', 'agent');
  }

  Future<void> updateAgent(Agent agent) async {
    await _agentRepository.updateAgent(agent);
    _logAgentEvent(agent.id, 'UPDATE_AGENT_ACCOUNT', 'Agent: ${agent.name}', 'agent');
  }

  Future<void> deleteAgent(String agentId) async {
    final agent = await getAgent(agentId);
    if (agent != null) {
      await _agentRepository.deleteAgent(agentId, userId);
      _logAgentEvent(agentId, 'DELETE_AGENT_ACCOUNT', 'Agent ID: $agentId', 'agent');
    }
  }

  Stream<List<Agent>> watchAgents({String? enterpriseId, AgentStatus? status, String? searchQuery}) {
    return _agentRepository.watchAgents(
      enterpriseId: enterpriseId ?? _activeEnterpriseId,
      status: status,
      searchQuery: searchQuery,
    );
  }

  /// Récupère les statistiques quotidiennes pour le réseau d'agents.
  Future<Map<String, dynamic>> getDailyStatistics({
    String? enterpriseId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    // 1. Récupérer les transactions du jour pour les entités accessibles
    final targetIds = enterpriseId != null 
        ? [enterpriseId] 
        : await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);
    
    // Pour simplifier, on récupère toutes les transactions et on filtre
    // (Dans une vraie prod, on utiliserait une requête filtrée par IDs)
    final transactions = await _transactionRepository.fetchTransactions(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    int rechargesToday = 0;
    int withdrawalsToday = 0;
    
    for (final t in transactions) {
      if (!targetIds.contains(t.enterpriseId)) continue;
      if (t.status != TransactionStatus.completed) continue;

      if (t.type == TransactionType.cashIn) {
        rechargesToday += t.amount;
      } else if (t.type == TransactionType.cashOut) {
        withdrawalsToday += t.amount;
      }
    }

    // 2. Compter les alertes de liquidité
    final allAgencies = await fetchAgencies(parentEnterpriseId: enterpriseId);
    final allAgents = await fetchAgents(enterpriseId: enterpriseId);
    
    // Low liquidity can be on both Agency (aggregated/cash) and Agent (SIM)
    int lowLiquidityAgencies = 0;
    int lowLiquidityAgents = 0;
    
    for (final a in allAgencies) {
      final threshold = a.metadata['criticalThreshold'] as int? ?? 50000;
      if ((a.floatBalance ?? 0) <= threshold) lowLiquidityAgencies++;
    }

    for (final a in allAgents) {
      if (a.isLowLiquidity(50000)) lowLiquidityAgents++;
    }

    return {
      'rechargesToday': rechargesToday,
      'withdrawalsToday': withdrawalsToday,
      'lowLiquidityAlerts': lowLiquidityAgencies + lowLiquidityAgents,
      'lowLiquidityAgencies': lowLiquidityAgencies,
      'lowLiquidityAgents': lowLiquidityAgents,
      'agentCount': allAgents.length,
      'agencyCount': allAgencies.length,
    };
  }

  /// Met à jour la liquidité d'une agence (recharge ou retrait interne).
  Future<Enterprise> updateAgencyLiquidity({
    required Enterprise agency,
    required int amount,
    required bool isRecharge,
    bool isCredit = false,
  }) async {
    var updatedAgency = agency;
    
    if (isRecharge) {
      final currentBalance = agency.floatBalance ?? 0;
      final currentDebt = agency.floatDebt ?? 0;
      
      updatedAgency = agency.copyWithOrangeMoneyMetadata(
        floatBalance: currentBalance + amount,
        floatDebt: isCredit ? currentDebt + amount : currentDebt,
      );
    } else {
      final currentBalance = agency.floatBalance ?? 0;
      updatedAgency = agency.copyWithOrangeMoneyMetadata(
        floatBalance: (currentBalance - amount).clamp(0, double.infinity).toInt(),
      );
    }

    await _enterpriseRepository.updateEnterprise(updatedAgency);
    
    _logAgentEvent(
      agency.id,
      isRecharge ? (isCredit ? 'AGENCY_CREDIT_SUPPLY' : 'AGENCY_CASH_SUPPLY') : 'AGENCY_WITHDRAW',
      'Agency: ${agency.name}, Amount: $amount, Credit: $isCredit',
      'agency',
    );
    
    return updatedAgency;
  }

  /// Met à jour la liquidité d'un agent (recharge ou retrait SIM).
  Future<Agent> updateAgentLiquidity({
    required Agent agent,
    required int amount,
    required bool isRecharge,
  }) async {
    final updatedAgent = agent.copyWith(
      liquidity: isRecharge ? agent.liquidity + amount : (agent.liquidity - amount).clamp(0, double.infinity).toInt(),
    );

    await _agentRepository.updateAgent(updatedAgent);
    
    _logAgentEvent(
      agent.id,
      isRecharge ? 'AGENT_SIM_RECHARGE' : 'AGENT_SIM_WITHDRAW',
      'Agent: ${agent.name}, Amount: $amount',
      'agent',
    );
    
    return updatedAgent;
  }

  /// Remboursement d'une dette par une agence.
  Future<Enterprise> repayAgencyDebt({
    required Enterprise agency,
    required int amount,
  }) async {
    final currentDebt = agency.floatDebt ?? 0;
    final newDebt = (currentDebt - amount).clamp(0, double.infinity).toInt();
    
    final updatedAgency = agency.copyWithOrangeMoneyMetadata(
      floatDebt: newDebt,
    );

    await _enterpriseRepository.updateEnterprise(updatedAgency);
    
    _logAgentEvent(
      agency.id,
      'AGENCY_DEBT_REPAYMENT',
      'Agency: ${agency.name}, Amount: $amount, Remaining Debt: $newDebt',
      'agency',
    );
    
    return updatedAgency;
  }

  void _logAgentEvent(String id, String action, String details, String type) {
    try {
      _auditTrailService.logAction(
        enterpriseId: _activeEnterpriseId,
        userId: userId,
        action: action,
        module: 'orange_money',
        entityId: id,
        entityType: type == 'agency' ? 'agency_enterprise' : 'agent_account',
        metadata: {'details': details},
      );
    } catch (e) {
      AppLogger.error('Failed to log agent audit', error: e);
    }
  }
}

import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/adapters/orange_money_permission_adapter.dart';

/// Controller for managing affiliated agents.
class AgentsController {
  AgentsController(
    this._repository,
    this._auditTrailService,
    this.userId,
    this._permissionAdapter,
    this._activeEnterpriseId,
  );

  final AgentRepository _repository;
  final AuditTrailService _auditTrailService;
  final String userId;
  final OrangeMoneyPermissionAdapter _permissionAdapter;
  final String _activeEnterpriseId;

  Future<List<Agent>> fetchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  }) async {
    // If specific enterprise requested, use it
    if (enterpriseId != null) {
      return await _repository.fetchAgents(
        enterpriseId: enterpriseId,
        status: status,
        searchQuery: searchQuery,
      );
    }

    // Otherwise, check hierarchy
    final accessibleIds = await _permissionAdapter.getAccessibleEnterpriseIds(_activeEnterpriseId);

    if (accessibleIds.length > 1) {
       // Note: Repository likely needs fetchAgentsByEnterprises or we iterate.
       // For now, let's assuming repo doesn't have it, we might need to iterate or add it to repo.
       // Checking AgentRepository... it might only have fetchAgents.
       // Let's check AgentRepository first.
       // Actually, to avoid breaking, let's implement basic iteration here if repo missing method.
       // But better to add it to repo.
       // Let's assume for now we use `activeEnterpriseId` if no method, 
       // OR even better: just iterate here if necessary.
       // Wait, I should have checked AgentRepository. 
       // I will assume for this step I need to add it or iterate.
       // Let's implement iteration as fallback safe approach.
       
       List<Agent> allAgents = [];
       for (final id in accessibleIds) {
          final agents = await _repository.fetchAgents(
            enterpriseId: id,
            status: status,
            searchQuery: searchQuery,
          );
          allAgents.addAll(agents);
       }
       return allAgents;
    }

    return await _repository.fetchAgents(
      enterpriseId: _activeEnterpriseId,
      status: status,
      searchQuery: searchQuery,
    );
  }

  Future<Agent?> getAgent(String agentId) async {
    return await _repository.getAgent(agentId);
  }

  Future<String> createAgent(Agent agent) async {
    final agentId = await _repository.createAgent(agent);
    _logAgentEvent(agent.enterpriseId, 'CREATE_AGENT', 'Agent: ${agent.name}');
    return agentId;
  }

  Future<void> updateAgent(Agent agent) async {
    await _repository.updateAgent(agent);
    _logAgentEvent(agent.enterpriseId, 'UPDATE_AGENT', 'Agent: ${agent.name}');
  }

  Future<void> deleteAgent(String agentId) async {
    final agent = await getAgent(agentId);
    if (agent != null) {
      await _repository.deleteAgent(agentId, userId);
      _logAgentEvent(agent.enterpriseId, 'DELETE_AGENT', 'Agent ID: $agentId');
    }
  }

  Future<void> restoreAgent(String agentId) async {
    await _repository.restoreAgent(agentId);
    final agent = await getAgent(agentId);
    if (agent != null) {
      _logAgentEvent(agent.enterpriseId, 'RESTORE_AGENT', 'Agent ID: $agentId');
    }
  }

  Stream<List<Agent>> watchAgents({String? enterpriseId}) {
    return _repository.watchAgents(enterpriseId: enterpriseId);
  }

  Stream<List<Agent>> watchDeletedAgents() {
    return _repository.watchDeletedAgents();
  }

  Future<Map<String, dynamic>> getDailyStatistics({
    String? enterpriseId,
    DateTime? date,
  }) async {
    return await _repository.getDailyStatistics(
      enterpriseId: enterpriseId,
      date: date,
    );
  }

  /// Met à jour la liquidité d'un agent (recharge ou retrait).
  /// Retourne l'agent mis à jour.
  Future<Agent> updateAgentLiquidity({
    required Agent agent,
    required int amount,
    required bool isRecharge,
  }) async {
    final newLiquidity = isRecharge
        ? agent.liquidity + amount
        : (agent.liquidity - amount).clamp(0, double.infinity).toInt();

    final updatedAgent = agent.copyWith(
      liquidity: newLiquidity,
      updatedAt: DateTime.now(),
    );

    await _repository.updateAgent(updatedAgent);
    _logAgentEvent(
      agent.enterpriseId,
      isRecharge ? 'AGENT_RECHARGE' : 'AGENT_WITHDRAW',
      'Agent: ${agent.name}, Amount: $amount, New Liquidity: $newLiquidity',
    );
    return updatedAgent;
  }

  void _logAgentEvent(String enterpriseId, String action, String details) {
    try {
      _auditTrailService.logAction(
        enterpriseId: enterpriseId,
        userId: userId,
        action: action,
        module: 'orange_money',
        entityId: '', // Generic agent event
        entityType: 'agent',
        metadata: {'details': details},
      );
    } catch (e) {
      AppLogger.error('Failed to log agent audit', error: e);
    }
  }
}

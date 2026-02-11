import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';

/// Controller for managing affiliated agents.
class AgentsController {
  AgentsController(this._repository, this._auditTrailService, this.userId);

  final AgentRepository _repository;
  final AuditTrailService _auditTrailService;
  final String userId;

  Future<List<Agent>> fetchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  }) async {
    return await _repository.fetchAgents(
      enterpriseId: enterpriseId,
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

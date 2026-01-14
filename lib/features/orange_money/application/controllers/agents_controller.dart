import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';

/// Controller for managing affiliated agents.
class AgentsController {
  AgentsController(this._repository);

  final AgentRepository _repository;

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
    return await _repository.createAgent(agent);
  }

  Future<void> updateAgent(Agent agent) async {
    return await _repository.updateAgent(agent);
  }

  Future<void> deleteAgent(String agentId) async {
    return await _repository.deleteAgent(agentId);
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

    final updatedAgent = Agent(
      id: agent.id,
      name: agent.name,
      phoneNumber: agent.phoneNumber,
      simNumber: agent.simNumber,
      operator: agent.operator,
      liquidity: newLiquidity,
      commissionRate: agent.commissionRate,
      status: agent.status,
      enterpriseId: agent.enterpriseId,
      createdAt: agent.createdAt,
      updatedAt: DateTime.now(),
    );

    await _repository.updateAgent(updatedAgent);
    return updatedAgent;
  }
}

import 'dart:async';

import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';

/// Mock implementation of AgentRepository for development.
class MockAgentRepository implements AgentRepository {
  final _agents = <String, Agent>{};

  MockAgentRepository() {
    // Initialize with sample data
    _agents['agent-1'] = Agent(
      id: 'agent-1',
      name: 'Jean Konaté',
      phoneNumber: '+22670123456',
      simNumber: 'sim_123456789',
      operator: MobileOperator.orange,
      liquidity: 500000,
      commissionRate: 2.5,
      status: AgentStatus.active,
      enterpriseId: 'orange_money_1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _agents['agent-2'] = Agent(
      id: 'agent-2',
      name: 'Marie Traoré',
      phoneNumber: '+22670234567',
      simNumber: 'sim_234567890',
      operator: MobileOperator.mtn,
      liquidity: 250000,
      commissionRate: 2.0,
      status: AgentStatus.active,
      enterpriseId: 'orange_money_1',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );
  }

  @override
  Future<List<Agent>> fetchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var agents = _agents.values.toList();

    if (enterpriseId != null) {
      agents = agents.where((a) => a.enterpriseId == enterpriseId).toList();
    }

    if (status != null) {
      agents = agents.where((a) => a.status == status).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      agents = agents.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.phoneNumber.contains(query) ||
            a.simNumber.toLowerCase().contains(query);
      }).toList();
    }

    agents.sort((a, b) => a.name.compareTo(b.name));
    return agents;
  }

  @override
  Future<Agent?> getAgent(String agentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _agents[agentId];
  }

  @override
  Future<String> createAgent(Agent agent) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _agents[agent.id] = agent;
    return agent.id;
  }

  @override
  Future<void> updateAgent(Agent agent) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _agents[agent.id] = agent;
  }

  @override
  Future<void> deleteAgent(String agentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _agents.remove(agentId);
  }

  @override
  Future<Map<String, dynamic>> getDailyStatistics({
    String? enterpriseId,
    DateTime? date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Mock statistics
    return {
      'rechargesToday': 0, // Recharges du jour
      'withdrawalsToday': 0, // Retraits du jour
      'lowLiquidityAlerts': 0, // Nombre d'alertes liquidité
    };
  }
}


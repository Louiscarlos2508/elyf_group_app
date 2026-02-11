import '../entities/agent.dart';

/// Repository for managing affiliated agents.
abstract class AgentRepository {
  Future<List<Agent>> fetchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery, // Recherche par nom, téléphone ou SIM
  });

  Future<Agent?> getAgent(String agentId);

  Future<String> createAgent(Agent agent);

  Future<void> updateAgent(Agent agent);

  Future<void> deleteAgent(String agentId, String userId);

  Future<void> restoreAgent(String agentId);

  Stream<List<Agent>> watchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  });

  Stream<List<Agent>> watchDeletedAgents();

  /// Obtenir les statistiques des agents pour une journée.
  Future<Map<String, dynamic>> getDailyStatistics({
    String? enterpriseId,
    DateTime? date,
  });
}

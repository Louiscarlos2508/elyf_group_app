import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';

/// Offline-first repository for Agent entities.
class AgentOfflineRepository extends OfflineRepository<Agent>
    implements AgentRepository {
  AgentOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'agents';

  @override
  Agent fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      simNumber: map['simNumber'] as String,
      operator: _parseOperator(map['operator'] as String),
      liquidity: (map['liquidity'] as num?)?.toInt() ?? 0,
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(map['status'] as String),
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Agent entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'phoneNumber': entity.phoneNumber,
      'simNumber': entity.simNumber,
      'operator': entity.operator.name,
      'liquidity': entity.liquidity.toDouble(),
      'commissionRate': entity.commissionRate,
      'status': entity.status.name,
      'enterpriseId': entity.enterpriseId,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Agent entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Agent entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Agent entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(Agent entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Agent entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'orange_money',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
  }

  @override
  Future<Agent?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Agent>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    final entities = rows

        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))

        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // AgentRepository interface implementation

  @override
  Future<List<Agent>> fetchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  }) async {
    try {
      AppLogger.debug(
        'Fetching agents for enterprise: ${enterpriseId ?? this.enterpriseId}',
        name: 'AgentOfflineRepository',
      );
      final allAgents = await getAllForEnterprise(
        enterpriseId ?? this.enterpriseId,
      );
      var filtered = allAgents;

      if (status != null) {
        filtered = filtered.where((a) => a.status == status).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered.where((a) {
          return a.name.toLowerCase().contains(query) ||
              a.phoneNumber.contains(query) ||
              a.simNumber.contains(query);
        }).toList();
      }

      return filtered;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching agents',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Agent?> getAgent(String agentId) async {
    try {
      return await getByLocalId(agentId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting agent: $agentId - ${appException.message}',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createAgent(Agent agent) async {
    try {
      final localId = getLocalId(agent);
      final agentWithLocalId = Agent(
        id: localId,
        name: agent.name,
        phoneNumber: agent.phoneNumber,
        simNumber: agent.simNumber,
        operator: agent.operator,
        liquidity: agent.liquidity,
        commissionRate: agent.commissionRate,
        status: agent.status,
        enterpriseId: agent.enterpriseId,
        createdAt: agent.createdAt,
        updatedAt: agent.updatedAt,
      );
      await save(agentWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating agent',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateAgent(Agent agent) async {
    try {
      await save(agent);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating agent: ${agent.id} - ${appException.message}',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteAgent(String agentId) async {
    try {
      final agent = await getAgent(agentId);
      if (agent != null) {
        await delete(agent);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting agent: $agentId - ${appException.message}',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Map<String, dynamic>> getDailyStatistics({
    String? enterpriseId,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final agents = await fetchAgents(
        enterpriseId: enterpriseId ?? this.enterpriseId,
      );

      final activeAgents = agents.where((a) => a.isActive).length;
      final totalLiquidity = agents.fold<int>(0, (sum, a) => sum + a.liquidity);
      final averageLiquidity = agents.isEmpty
          ? 0.0
          : totalLiquidity / agents.length;

      return {
        'totalAgents': agents.length,
        'activeAgents': activeAgents,
        'totalLiquidity': totalLiquidity,
        'averageLiquidity': averageLiquidity,
        'date': targetDate.toIso8601String(),
      };
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting daily statistics: ${appException.message}',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  AgentStatus _parseStatus(String status) {
    switch (status) {
      case 'active':
        return AgentStatus.active;
      case 'inactive':
        return AgentStatus.inactive;
      case 'suspended':
        return AgentStatus.suspended;
      default:
        return AgentStatus.inactive;
    }
  }

  MobileOperator _parseOperator(String operator) {
    switch (operator) {
      case 'orange':
        return MobileOperator.orange;
      case 'mtn':
        return MobileOperator.mtn;
      case 'moov':
        return MobileOperator.moov;
      case 'other':
        return MobileOperator.other;
      default:
        return MobileOperator.other;
    }
  }
}

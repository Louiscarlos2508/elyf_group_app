import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
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
    required this.auditTrailRepository,
    required this.userId,
  });

  final String enterpriseId;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'agents';

  @override
  Agent fromMap(Map<String, dynamic> map) {
    return Agent.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Agent entity) {
    return entity.toMap();
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
  Future<void> saveToLocal(Agent entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
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
  Future<void> deleteFromLocal(Agent entity, {String? userId}) async {
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
        .where((a) => !a.isDeleted)
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
      AppLogger.error(
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
      final now = DateTime.now();
      final agentWithLocalId = agent.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: agent.createdAt ?? now,
        updatedAt: now,
      );
      await save(agentWithLocalId);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: syncManager.getUserId() ?? '',
          module: 'orange_money',
          action: 'create_agent',
          entityId: localId,
          entityType: 'agent',
          metadata: {
            'name': agent.name,
            'phoneNumber': agent.phoneNumber,
          },
          timestamp: now,
        ),
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
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
      final now = DateTime.now();
      final updatedAgent = agent.copyWith(updatedAt: now);
      await save(updatedAgent);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: syncManager.getUserId() ?? '',
          module: 'orange_money',
          action: 'update_agent',
          entityId: agent.id,
          entityType: 'agent',
          metadata: {
            'name': agent.name,
            'status': agent.status.name,
          },
          timestamp: now,
        ),
      );
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
  Future<void> deleteAgent(String agentId, String userId) async {
    try {
      final agent = await getAgent(agentId);
      if (agent != null) {
        final now = DateTime.now();
        final updatedAgent = agent.copyWith(
          deletedAt: now,
          deletedBy: userId,
          updatedAt: now,
        );
        await save(updatedAgent);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: syncManager.getUserId() ?? '',
            module: 'orange_money',
            action: 'delete_agent',
            entityId: agentId,
            entityType: 'agent',
            metadata: {'name': agent.name},
            timestamp: now,
          ),
        );
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
  Future<void> restoreAgent(String agentId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'orange_money',
      );
      
      final row = rows.firstWhere(
        (r) {
          final data = jsonDecode(r.dataJson) as Map<String, dynamic>;
          return data['id'] == agentId || r.localId == agentId;
        },
      );

      final agent = fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
      
      final now = DateTime.now();
      final updatedAgent = agent.copyWith(
        deletedAt: null,
        deletedBy: null,
        updatedAt: now,
      );
      await save(updatedAgent);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: syncManager.getUserId() ?? '',
          module: 'orange_money',
          action: 'restore_agent',
          entityId: agentId,
          entityType: 'agent',
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring agent: $agentId',
        name: 'AgentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Agent>> watchAgents({
    String? enterpriseId,
    AgentStatus? status,
    String? searchQuery,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId ?? this.enterpriseId,
          moduleType: 'orange_money',
        )
        .map((rows) {
      var agents = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((a) => !a.isDeleted)
          .toList();

      if (status != null) {
        agents = agents.where((a) => a.status == status).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        agents = agents.where((a) {
          return a.name.toLowerCase().contains(query) ||
              a.phoneNumber.contains(query) ||
              a.simNumber.contains(query);
        }).toList();
      }

      agents.sort((a, b) => a.name.compareTo(b.name));
      return deduplicateByRemoteId(agents);
    });
  }

  @override
  Stream<List<Agent>> watchDeletedAgents() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'orange_money',
        )
        .map((rows) {
      final agents = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((a) => a.isDeleted)
          .toList();

      agents.sort((a, b) => (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
      return deduplicateByRemoteId(agents);
    });
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
}

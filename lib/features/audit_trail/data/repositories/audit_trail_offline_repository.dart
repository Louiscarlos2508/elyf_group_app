import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/security/ledger_hasher.dart';
import '../../domain/entities/audit_record.dart';
import '../../domain/repositories/audit_trail_repository.dart';

class AuditTrailOfflineRepository extends OfflineRepository<AuditRecord>
    implements AuditTrailRepository {
  AuditTrailOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
  });

  @override
  String get collectionName => 'audit_trail';

  @override
  AuditRecord fromMap(Map<String, dynamic> map) {
    return AuditRecord(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String,
      userId: map['userId'] as String,
      module: map['module'] as String,
      action: map['action'] as String,
      entityId: map['entityId'] as String,
      entityType: map['entityType'] as String,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      hash: map['hash'] as String?,
      previousHash: map['previousHash'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(AuditRecord entity) {
    return {
      'id': entity.id,
      'enterpriseId': entity.enterpriseId,
      'userId': entity.userId,
      'module': entity.module,
      'action': entity.action,
      'entityId': entity.entityId,
      'entityType': entity.entityType,
      'metadata': entity.metadata,
      'hash': entity.hash,
      'previousHash': entity.previousHash,
      'timestamp': entity.timestamp.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(AuditRecord entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(AuditRecord entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(AuditRecord entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(AuditRecord entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: entity.enterpriseId,
      moduleType: 'audit_trail',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(AuditRecord entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: entity.enterpriseId,
        moduleType: 'audit_trail',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: entity.enterpriseId,
      moduleType: 'audit_trail',
    );
  }

  @override
  Future<AuditRecord?> getByLocalId(String localId) async {
    // Audit records are usually not fetched by single ID by users, but implemented for completeness
    final row = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: '', // Context needed if we really wanted to support this
      moduleType: 'audit_trail',
    );
    if (row == null) return null;
    return fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<AuditRecord>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'audit_trail',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuditRecord>> getAllForEnterprises(List<String> enterpriseIds) async {
    final rows = await driftService.records.listForEnterprises(
      collectionName: collectionName,
      enterpriseIds: enterpriseIds,
      moduleType: 'audit_trail',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AuditRecord>> fetchRecords({
    required String enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
    String? module,
    String? action,
    String? entityId,
    String? userId,
  }) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      return _filterRecords(
        all,
        startDate: startDate,
        endDate: endDate,
        module: module,
        action: action,
        entityId: entityId,
        userId: userId,
      );
    } catch (e, stack) {
      final appException = ErrorHandler.instance.handleError(e, stack);
      AppLogger.error('Error fetching audit records', error: e, stackTrace: stack);
      throw appException;
    }
  }

  @override
  Future<List<AuditRecord>> fetchRecordsForEnterprises({
    required List<String> enterpriseIds,
    DateTime? startDate,
    DateTime? endDate,
    String? module,
    String? action,
    String? entityId,
    String? userId,
  }) async {
    try {
      final all = await getAllForEnterprises(enterpriseIds);
      return _filterRecords(
        all,
        startDate: startDate,
        endDate: endDate,
        module: module,
        action: action,
        entityId: entityId,
        userId: userId,
      );
    } catch (e, stack) {
      final appException = ErrorHandler.instance.handleError(e, stack);
      AppLogger.error('Error fetching audit records for enterprises', error: e, stackTrace: stack);
      throw appException;
    }
  }

  List<AuditRecord> _filterRecords(
    List<AuditRecord> records, {
    DateTime? startDate,
    DateTime? endDate,
    String? module,
    String? action,
    String? entityId,
    String? userId,
  }) {
    var filtered = List<AuditRecord>.from(records);

    if (startDate != null) {
      filtered = filtered.where((r) => r.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((r) => r.timestamp.isBefore(endDate)).toList();
    }
    if (module != null) {
      filtered = filtered.where((r) => r.module == module).toList();
    }
    if (action != null) {
      filtered = filtered.where((r) => r.action == action).toList();
    }
    if (entityId != null) {
      filtered = filtered.where((r) => r.entityId == entityId).toList();
    }
    if (userId != null) {
      filtered = filtered.where((r) => r.userId == userId).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  @override
  Future<String> log(AuditRecord record) async {
    try {
      final localId = getLocalId(record);
      
      // Get previous hash for chaining
      String? previousHash;
      final enterpriseId = record.enterpriseId;
      
      final latestRecords = await fetchRecords(
        enterpriseId: enterpriseId,
        module: record.module,
      );
      
      if (latestRecords.isNotEmpty) {
        // fetchRecords sorts by timestamp desc, so first is latest
        previousHash = latestRecords.first.hash;
      }

      final hash = LedgerHasher.calculateHash(record, previousHash);

      final recordToSave = record.copyWith(
        id: localId,
        hash: hash,
        previousHash: previousHash,
        updatedAt: DateTime.now(),
      );
      
      await save(recordToSave);
      return localId;
    } catch (e, stack) {
      final appException = ErrorHandler.instance.handleError(e, stack);
      AppLogger.error('Error logging audit record', error: e, stackTrace: stack);
      throw appException;
    }
  }

  /// Deletes an audit record by ID for a given enterprise.
  ///
  /// This does **not** override [OfflineRepository.delete] which expects
  /// an entity instance. Instead, it is a domain-specific operation
  /// exposed via [AuditTrailRepository].
  @override
  Future<void> deleteRecord(String recordId, String enterpriseId) async {
    // Usually not needed for audit logs
    final records = await getAllForEnterprise(enterpriseId);
    final target = records.firstWhere((r) => r.id == recordId);
    await deleteFromLocal(target);
  }
}

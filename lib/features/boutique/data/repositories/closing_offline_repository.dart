
import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/closing.dart';
import '../../domain/repositories/closing_repository.dart';

/// Offline-first repository for Closing entities.
class ClosingOfflineRepository extends OfflineRepository<Closing>
    implements ClosingRepository {
  ClosingOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'closings';

  @override
  Closing fromMap(Map<String, dynamic> map) {
    return Closing.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Closing entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Closing entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Closing entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Closing entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Closing entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Closing entity, {String? userId}) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Closing?> getByLocalId(String localId) async {
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal != null) {
      return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    }

    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote == null) return null;
    return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Closing>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final closings = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    final deduplicated = deduplicateByRemoteId(closings);
    deduplicated.sort((a, b) => b.date.compareTo(a.date));
    return deduplicated;
  }

  @override
  Future<List<Closing>> fetchClosings({int limit = 50}) async {
    final all = await getAllForEnterprise(enterpriseId);
    return all.take(limit).toList();
  }

  @override
  Future<int> getCountForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    final closings = await getClosingsInPeriod(start, end);
    return closings.length;
  }

  @override
  Future<Closing?> getClosing(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<Closing?> getActiveSession() async {
    final all = await getAllForEnterprise(enterpriseId);
    try {
      return all.firstWhere((c) => c.status == ClosingStatus.open);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createClosing(Closing closing) async {
    final localId = getLocalId(closing);
    final newClosing = closing.copyWith(
      id: localId,
      enterpriseId: enterpriseId,
    );
    await save(newClosing);
      
    await _logAudit(
      action: closing.status == ClosingStatus.open ? 'open_session' : 'create_closing',
      entityId: localId,
      metadata: {
        'date': closing.date.toIso8601String(),
        'discrepancy': closing.discrepancy,
        'status': closing.status.name,
      },
    );

    return localId;
  }

  @override
  Future<void> updateClosing(Closing closing) async {
    await save(closing);
    await _logAudit(
      action: 'update_closing',
      entityId: closing.id,
      metadata: {
        'status': closing.status.name,
        'discrepancy': closing.discrepancy,
      },
    );
  }

  @override
  Future<List<Closing>> getClosingsInPeriod(DateTime start, DateTime end) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      return all.where((c) {
        return c.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            c.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Stream<List<Closing>> watchClosings({int limit = 50}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final closings = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .toList();
      final deduplicated = deduplicateByRemoteId(closings);
      deduplicated.sort((a, b) => b.date.compareTo(a.date));
      return deduplicated.take(limit).toList();
    });
  }

  @override
  Stream<Closing?> watchActiveSession() {
    return watchClosings().map((closings) {
      try {
        return closings.firstWhere((c) => c.status == ClosingStatus.open);
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> _logAudit({
    required String action,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await auditTrailRepository.log(
        AuditRecord(
          id: '',
          enterpriseId: enterpriseId,
          userId: syncManager.getUserId() ?? '',
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'closing',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log closing audit: $action', error: e);
    }
  }
}

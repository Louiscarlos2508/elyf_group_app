import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../../core/errors/error_handler.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/offline/drift_service.dart';
import '../../../domain/entities/audit_log.dart';
import '../../../domain/services/audit/audit_service.dart';
import '../firestore_sync_service.dart';

/// Offline-first implementation of AuditService using Drift.
///
/// Enregistre les logs localement et synchronise avec Firestore.
class AuditOfflineService implements AuditService {
  AuditOfflineService({required this.driftService, this.firestoreSync});

  final DriftService driftService;
  final FirestoreSyncService? firestoreSync;

  static const String _collectionName = 'audit_logs';

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.toRadixString(36);
    return 'audit_${timestamp}_$random';
  }

  @override
  Future<void> logAction({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String userId,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? moduleId,
    String? enterpriseId,
    String? userDisplayName,
  }) async {
    try {
      final log = AuditLog(
        id: _generateId(),
        action: action,
        entityType: entityType,
        entityId: entityId,
        userId: userId,
        timestamp: DateTime.now(),
        description: description,
        oldValue: oldValue,
        newValue: newValue,
        moduleId: moduleId,
        enterpriseId: enterpriseId,
        userDisplayName: userDisplayName,
      );

      final map = log.toMap()..['localId'] = log.id;

      // Sauvegarder localement dans Drift (SQLite)
      await driftService.records.upsert(
        collectionName: _collectionName,
        localId: log.id,
        remoteId:
            log.id, // Utiliser l'ID local comme remoteId pour les audit logs
        enterpriseId: enterpriseId ?? 'global',
        moduleType: moduleId ?? 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      developer.log(
        'Audit log created locally: ${action.name} on $entityType/$entityId by $userId',
        name: 'admin.audit',
      );

      // Synchroniser avec Firestore (en arrière-plan, sans bloquer)
      if (firestoreSync != null) {
        // Ne pas attendre - la synchronisation se fait en arrière-plan
        firestoreSync!.syncAuditLogToFirestore(log).catchError((e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Error syncing audit log to Firestore (log saved locally): ${appException.message}',
            name: 'admin.audit',
            error: e,
            stackTrace: stackTrace,
          );
        });
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error creating audit log: ${appException.message}',
        name: 'admin.audit',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - audit logging should not break the application
    }
  }

  @override
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      return records
          .map((record) {
            final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
            return AuditLog.fromMap(map);
          })
          .where((log) {
            return log.entityType == entityType && log.entityId == entityId;
          })
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching audit logs: ${appException.message}',
        name: 'admin.audit',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<AuditLog>> getLogsForUser(String userId) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      return records
          .map((record) {
            final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
            return AuditLog.fromMap(map);
          })
          .where((log) => log.userId == userId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching audit logs for user: ${appException.message}',
        name: 'admin.audit',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<AuditLog>> getLogsForModule(String moduleId) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      return records
          .map((record) {
            final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
            return AuditLog.fromMap(map);
          })
          .where((log) => log.moduleId == moduleId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching audit logs for module: ${appException.message}',
        name: 'admin.audit',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<AuditLog>> getLogsForEnterprise(String enterpriseId) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'administration',
      );

      return records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return AuditLog.fromMap(map);
      }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching audit logs for enterprise: ${appException.message}',
        name: 'admin.audit',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<AuditLog>> getRecentLogs({
    int limit = 50,
    DateTime? since,
  }) async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      var logs = records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return AuditLog.fromMap(map);
      }).toList();

      if (since != null) {
        logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
      }

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs.take(limit).toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching recent audit logs: ${appException.message}',
        name: 'admin.audit',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}

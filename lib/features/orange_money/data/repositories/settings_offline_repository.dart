import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Offline-first repository for OrangeMoneySettings entities.
class SettingsOfflineRepository extends OfflineRepository<OrangeMoneySettings>
    implements SettingsRepository {
  SettingsOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.auditTrailRepository,
    required this.userId,
    this.moduleType = 'orange_money',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'orange_money_settings';

  @override
  OrangeMoneySettings fromMap(Map<String, dynamic> map) {
    return OrangeMoneySettings.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(OrangeMoneySettings entity) {
    return entity.toMap();
  }

  String _getSettingsId(String enterpriseId) => 'settings_$enterpriseId';

  @override
  String getLocalId(OrangeMoneySettings entity) =>
      _getSettingsId(entity.enterpriseId);

  @override
  String? getRemoteId(OrangeMoneySettings entity) =>
      _getSettingsId(entity.enterpriseId);

  @override
  String? getEnterpriseId(OrangeMoneySettings entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(OrangeMoneySettings entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(OrangeMoneySettings entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<OrangeMoneySettings?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (record == null) return null;
    return fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<OrangeMoneySettings>> getAllForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows

        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))

        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // SettingsRepository implementation

  @override
  Future<OrangeMoneySettings?> getSettings(String enterpriseId) async {
    try {
      final settingsId = _getSettingsId(enterpriseId);
      return await getByLocalId(settingsId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting settings',
        name: 'SettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> saveSettings(OrangeMoneySettings settings) async {
    try {
      final now = DateTime.now();
      final updated = settings.copyWith(
        createdAt: settings.createdAt ?? now,
        updatedAt: now,
      );
      await save(updated);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'update_settings',
          entityId: _getSettingsId(settings.enterpriseId),
          entityType: 'settings',
          metadata: {
            'simNumber': settings.simNumber,
          },
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error saving settings: ${appException.message}',
        name: 'SettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateNotifications(
    String enterpriseId,
    NotificationSettings notifications,
  ) async {
    try {
      final current = await getSettings(enterpriseId);
      if (current != null) {
        final now = DateTime.now();
        final updated = current.copyWith(
          notifications: notifications,
          updatedAt: now,
        );
        await save(updated);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: userId,
            module: 'orange_money',
            action: 'update_notifications',
            entityId: _getSettingsId(enterpriseId),
            entityType: 'settings',
            metadata: {
              'lowLiquidityAlert': notifications.lowLiquidityAlert,
              'paymentDueAlert': notifications.paymentDueAlert,
            },
            timestamp: now,
          ),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating notifications: ${appException.message}',
        name: 'SettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateThresholds(
    String enterpriseId,
    ThresholdSettings thresholds,
  ) async {
    try {
      final current = await getSettings(enterpriseId);
      if (current != null) {
        final now = DateTime.now();
        final updated = current.copyWith(
          thresholds: thresholds,
          updatedAt: now,
        );
        await save(updated);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: userId,
            module: 'orange_money',
            action: 'update_thresholds',
            entityId: _getSettingsId(enterpriseId),
            entityType: 'settings',
            metadata: {
              'criticalLiquidityThreshold': thresholds.criticalLiquidityThreshold,
              'paymentDueDaysBefore': thresholds.paymentDueDaysBefore,
            },
            timestamp: now,
          ),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating thresholds',
        name: 'SettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateSimNumber(String enterpriseId, String simNumber) async {
    try {
      final current = await getSettings(enterpriseId);
      if (current != null) {
        final now = DateTime.now();
        final updated = current.copyWith(
          simNumber: simNumber,
          updatedAt: now,
        );
        await save(updated);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: userId,
            module: 'orange_money',
            action: 'update_sim_number',
            entityId: _getSettingsId(enterpriseId),
            entityType: 'settings',
            metadata: {'simNumber': simNumber},
            timestamp: now,
          ),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating SIM number: ${appException.message}',
        name: 'SettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<OrangeMoneySettings?> watchSettings(String enterpriseId) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      if (rows.isEmpty) return null;
      // Il n'y a qu'un seul record de settings par entreprise
      return fromMap(jsonDecode(rows.first.dataJson) as Map<String, dynamic>);
    });
  }
}

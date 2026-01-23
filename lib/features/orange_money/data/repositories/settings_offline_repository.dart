import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
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
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'orange_money_settings';

  @override
  OrangeMoneySettings fromMap(Map<String, dynamic> map) {
    final notificationsMap =
        map['notifications'] as Map<String, dynamic>? ?? {};
    final thresholdsMap = map['thresholds'] as Map<String, dynamic>? ?? {};

    return OrangeMoneySettings(
      enterpriseId: map['enterpriseId'] as String,
      notifications: NotificationSettings(
        lowLiquidityAlert:
            notificationsMap['lowLiquidityAlert'] as bool? ?? true,
        monthlyCommissionReminder:
            notificationsMap['monthlyCommissionReminder'] as bool? ?? true,
        paymentDueAlert: notificationsMap['paymentDueAlert'] as bool? ?? true,
      ),
      thresholds: ThresholdSettings(
        criticalLiquidityThreshold:
            (thresholdsMap['criticalLiquidityThreshold'] as num?)?.toInt() ??
            50000,
        paymentDueDaysBefore:
            (thresholdsMap['paymentDueDaysBefore'] as num?)?.toInt() ?? 3,
      ),
      simNumber: map['simNumber'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(OrangeMoneySettings entity) {
    return {
      'enterpriseId': entity.enterpriseId,
      'notifications': {
        'lowLiquidityAlert': entity.notifications.lowLiquidityAlert,
        'monthlyCommissionReminder':
            entity.notifications.monthlyCommissionReminder,
        'paymentDueAlert': entity.notifications.paymentDueAlert,
      },
      'thresholds': {
        'criticalLiquidityThreshold':
            entity.thresholds.criticalLiquidityThreshold,
        'paymentDueDaysBefore': entity.thresholds.paymentDueDaysBefore,
      },
      'simNumber': entity.simNumber,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
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
      developer.log(
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
      final updated = OrangeMoneySettings(
        enterpriseId: settings.enterpriseId,
        notifications: settings.notifications,
        thresholds: settings.thresholds,
        simNumber: settings.simNumber,
        createdAt: settings.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(updated);
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
        final updated = OrangeMoneySettings(
          enterpriseId: current.enterpriseId,
          notifications: notifications,
          thresholds: current.thresholds,
          simNumber: current.simNumber,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        await save(updated);
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
        final updated = OrangeMoneySettings(
          enterpriseId: current.enterpriseId,
          notifications: current.notifications,
          thresholds: thresholds,
          simNumber: current.simNumber,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        await save(updated);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
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
        final updated = OrangeMoneySettings(
          enterpriseId: current.enterpriseId,
          notifications: current.notifications,
          thresholds: current.thresholds,
          simNumber: simNumber,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        await save(updated);
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
}

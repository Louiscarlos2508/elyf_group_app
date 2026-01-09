import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Offline-first repository for OrangeMoneySettings (orange_money module).
///
/// Les settings sont stockés avec enterpriseId comme document ID.
class SettingsOfflineRepository implements SettingsRepository {
  SettingsOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  static const String _collectionName = 'orange_money_settings';

  OrangeMoneySettings _fromMap(Map<String, dynamic> map) {
    return OrangeMoneySettings(
      enterpriseId: map['enterpriseId'] as String,
      notifications: NotificationSettings(
        lowLiquidityAlert: map['notifications']?['lowLiquidityAlert'] as bool? ?? true,
        monthlyCommissionReminder: map['notifications']?['monthlyCommissionReminder'] as bool? ?? true,
        paymentDueAlert: map['notifications']?['paymentDueAlert'] as bool? ?? true,
      ),
      thresholds: ThresholdSettings(
        criticalLiquidityThreshold: (map['thresholds']?['criticalLiquidityThreshold'] as num?)?.toInt() ?? 50000,
        paymentDueDaysBefore: (map['thresholds']?['paymentDueDaysBefore'] as num?)?.toInt() ?? 3,
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

  Map<String, dynamic> _toMap(OrangeMoneySettings settings) {
    return {
      'enterpriseId': settings.enterpriseId,
      'notifications': {
        'lowLiquidityAlert': settings.notifications.lowLiquidityAlert,
        'monthlyCommissionReminder': settings.notifications.monthlyCommissionReminder,
        'paymentDueAlert': settings.notifications.paymentDueAlert,
      },
      'thresholds': {
        'criticalLiquidityThreshold': settings.thresholds.criticalLiquidityThreshold,
        'paymentDueDaysBefore': settings.thresholds.paymentDueDaysBefore,
      },
      'simNumber': settings.simNumber,
      'createdAt': settings.createdAt?.toIso8601String(),
      'updatedAt': settings.updatedAt?.toIso8601String(),
    };
  }

  @override
  Future<OrangeMoneySettings?> getSettings(String enterpriseId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'orange_money',
      );

      if (rows.isEmpty) {
        return null;
      }

      // Prendre le premier (il ne devrait y en avoir qu'un par entreprise)
      final row = rows.first;
      final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
      return _fromMap(map);
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting settings',
        name: 'SettingsOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<void> saveSettings(OrangeMoneySettings settings) async {
    try {
      final localId = 'settings_${settings.enterpriseId}';
      final map = _toMap(settings)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _collectionName,
        localId: localId,
        remoteId: null, // Settings n'ont pas d'ID distant unique
        enterpriseId: settings.enterpriseId,
        moduleType: 'orange_money',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _collectionName,
        documentId: localId,
        operationType: 'set',
        payload: map,
        enterpriseId: settings.enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error saving settings',
        name: 'SettingsOfflineRepository',
        error: appException,
      );
      rethrow;
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
        await saveSettings(updated);
      } else {
        // Créer avec les notifications fournies et valeurs par défaut
        final newSettings = OrangeMoneySettings(
          enterpriseId: enterpriseId,
          notifications: notifications,
          thresholds: const ThresholdSettings(),
          simNumber: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveSettings(newSettings);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating notifications',
        name: 'SettingsOfflineRepository',
        error: appException,
      );
      rethrow;
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
        await saveSettings(updated);
      } else {
        // Créer avec les thresholds fournis et valeurs par défaut
        final newSettings = OrangeMoneySettings(
          enterpriseId: enterpriseId,
          notifications: const NotificationSettings(),
          thresholds: thresholds,
          simNumber: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveSettings(newSettings);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating thresholds',
        name: 'SettingsOfflineRepository',
        error: appException,
      );
      rethrow;
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
        await saveSettings(updated);
      } else {
        // Créer avec le simNumber fourni et valeurs par défaut
        final newSettings = OrangeMoneySettings(
          enterpriseId: enterpriseId,
          notifications: const NotificationSettings(),
          thresholds: const ThresholdSettings(),
          simNumber: simNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveSettings(newSettings);
      }
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating sim number',
        name: 'SettingsOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }
}


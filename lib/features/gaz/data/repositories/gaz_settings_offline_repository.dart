import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/gaz_settings.dart';
import '../../domain/repositories/gaz_settings_repository.dart';

/// Offline-first repository for GazSettings (gaz module).
///
/// Les settings sont stockés avec enterpriseId et moduleId comme clé.
class GazSettingsOfflineRepository implements GazSettingsRepository {
  GazSettingsOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  static const String _collectionName = 'gaz_settings';

  GazSettings _fromMap(Map<String, dynamic> map) {
    final wholesalePricesMap = map['wholesalePrices'] as Map<String, dynamic>?;
    final wholesalePrices = wholesalePricesMap?.map(
          (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
        ) ??
        {};

    return GazSettings(
      enterpriseId: map['enterpriseId'] as String,
      moduleId: map['moduleId'] as String,
      wholesalePrices: wholesalePrices,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _toMap(GazSettings settings) {
    return {
      'enterpriseId': settings.enterpriseId,
      'moduleId': settings.moduleId,
      'wholesalePrices': settings.wholesalePrices.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'updatedAt': settings.updatedAt?.toIso8601String(),
    };
  }

  @override
  Future<GazSettings?> getSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      for (final row in rows) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          final settings = _fromMap(map);
          if (settings.moduleId == moduleId) {
            return settings;
          }
        } catch (e) {
          developer.log(
            'Error parsing settings: $e',
            name: 'GazSettingsOfflineRepository',
          );
          continue;
        }
      }
      return null;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting settings',
        name: 'GazSettingsOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<void> saveSettings(GazSettings settings) async {
    try {
      final localId = 'settings_${settings.enterpriseId}_${settings.moduleId}';
      final map = _toMap(settings)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _collectionName,
        localId: localId,
        remoteId: null, // Settings n'ont pas d'ID distant unique
        enterpriseId: settings.enterpriseId,
        moduleType: 'gaz',
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
        name: 'GazSettingsOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      final localId = 'settings_${enterpriseId}_$moduleId';

      await driftService.records.deleteByLocalId(
        collectionName: _collectionName,
        localId: localId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      // Sync automatique
      await syncManager.enqueueOperation(
        collectionName: _collectionName,
        documentId: localId,
        operationType: 'delete',
        payload: {},
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting settings',
        name: 'GazSettingsOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }
}


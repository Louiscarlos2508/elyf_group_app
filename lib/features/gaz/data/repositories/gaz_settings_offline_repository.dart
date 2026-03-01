import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/gaz_settings.dart';
import '../../domain/repositories/gaz_settings_repository.dart';

/// Offline-first repository for GazSettings entities.
class GazSettingsOfflineRepository extends OfflineRepository<GazSettings>
    implements GazSettingsRepository {
  GazSettingsOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'gaz_settings';

  @override
  GazSettings fromMap(Map<String, dynamic> map) =>
      GazSettings.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(GazSettings entity) => entity.toMap();

  String _getSettingsId(String enterpriseId, String moduleId) {
    return 'settings_${enterpriseId}_$moduleId';
  }

  @override
  String getLocalId(GazSettings entity) {
    return _getSettingsId(entity.enterpriseId, entity.moduleId);
  }

  @override
  String? getRemoteId(GazSettings entity) {
    return _getSettingsId(entity.enterpriseId, entity.moduleId);
  }

  @override
  String? getEnterpriseId(GazSettings entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(GazSettings entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
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
  Future<void> deleteFromLocal(GazSettings entity, {String? userId}) async {
    // Soft-delete
    final deletedSettings = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedSettings, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted gaz settings: ${entity.enterpriseId}',
      name: 'GazSettingsOfflineRepository',
    );
  }

  @override
  Future<GazSettings?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (record == null) return null;
    final settings = fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
    return settings.isDeleted ? null : settings;
  }

  @override
  Future<List<GazSettings>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows

      .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
      .where((s) => !s.isDeleted)
      .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // GazSettingsRepository implementation

  @override
  Future<GazSettings?> getSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      final allSettings = await getAllForEnterprise(enterpriseId);
      final settings = allSettings.where((s) => s.moduleId == moduleId).firstOrNull;
      
      // Fallback: si on n'a qu'un seul settings mais avec un moduleId vide (ex: configuré manuellement depuis Firebase)
      if (settings == null && allSettings.isNotEmpty) {
        return allSettings.first;
      }
      
      return settings;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting settings for $enterpriseId: ${appException.message}',
        name: 'GazSettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Stream<GazSettings?> watchSettings({
    required String enterpriseId,
    required String moduleId,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final row = rows.firstOrNull;
          if (row == null) return null;
          try {
            final settings = fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
            return settings.isDeleted ? null : settings;
          } catch (e) {
            return null;
          }
        });
  }

  @override
  Future<void> saveSettings(GazSettings settings) async {
    try {
      final updated = settings.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error saving settings: ${appException.message}',
        name: 'GazSettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      final settings = await getSettings(
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );
      if (settings != null) {
        await delete(settings);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting settings: ${appException.message}',
        name: 'GazSettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

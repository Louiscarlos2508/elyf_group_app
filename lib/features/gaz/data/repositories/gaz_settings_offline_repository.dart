import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
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
  GazSettings fromMap(Map<String, dynamic> map) {
    final wholesalePricesRaw = map['wholesalePrices'] as Map<String, dynamic>?;
    final wholesalePrices =
        wholesalePricesRaw?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
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

  @override
  Map<String, dynamic> toMap(GazSettings entity) {
    return {
      'enterpriseId': entity.enterpriseId,
      'moduleId': entity.moduleId,
      'wholesalePrices': entity.wholesalePrices.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

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
  Future<void> saveToLocal(GazSettings entity) async {
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
  Future<void> deleteFromLocal(GazSettings entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
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
    return fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<GazSettings>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // GazSettingsRepository implementation

  @override
  Future<GazSettings?> getSettings({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      final settingsId = _getSettingsId(enterpriseId, moduleId);
      return await getByLocalId(settingsId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting settings',
        name: 'GazSettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> saveSettings(GazSettings settings) async {
    try {
      final updated = settings.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error saving settings',
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
      developer.log(
        'Error deleting settings',
        name: 'GazSettingsOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

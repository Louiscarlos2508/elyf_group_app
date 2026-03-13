import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/collection_names.dart';
import '../../domain/entities/eau_minerale_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Offline-first repository for Eau Minérale settings with sync support.
class SettingsOfflineRepository extends OfflineRepository<EauMineraleSettings>
    implements EauMineraleSettingsRepository {
  SettingsOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => CollectionNames.eauMineraleSettings;

  String get moduleType => 'eau_minerale';

  @override
  String getLocalId(EauMineraleSettings entity) => 'settings_global';

  @override
  String? getRemoteId(EauMineraleSettings entity) => 'settings_global';

  @override
  String? getEnterpriseId(EauMineraleSettings entity) => enterpriseId;

  @override
  EauMineraleSettings fromMap(Map<String, dynamic> map) => 
      EauMineraleSettings.fromMap(map, 'settings_global');

  @override
  Map<String, dynamic> toMap(EauMineraleSettings entity) => 
      entity.toMap();

  @override
  Future<List<EauMineraleSettings>> getAllForEnterprise(String enterpriseId) async {
    final records = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return records
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
  }

  @override
  Future<EauMineraleSettings?> getSettings() async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: 'settings_global',
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    return map != null ? fromMap(map) : null;
  }

  @override
  Stream<EauMineraleSettings?> watchSettings() {
    return driftService.records
        .watchByLocalId(
          collectionName: collectionName,
          localId: 'settings_global',
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((record) {
      if (record == null) return null;
      final map = safeDecodeJson(record.dataJson, record.localId);
      return map != null ? fromMap(map) : null;
    });
  }

  @override
  Future<void> saveSettings(EauMineraleSettings settings) async {
    final map = toMap(settings);
    
    await driftService.records.upsert(
      userId: syncManager.getUserId() ?? '',
      collectionName: collectionName,
      localId: 'settings_global',
      remoteId: 'settings_global',
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );

    // Trigger sync immediately if online
    if (connectivityService.isOnline) {
      syncManager.syncPendingOperations();
    }
  }

  @override
  Future<void> saveToLocal(EauMineraleSettings entity, {String? userId}) async {
    await saveSettings(entity);
  }

  @override
  Future<void> deleteFromLocal(EauMineraleSettings entity, {String? userId}) async {
    // Not applicable for global settings
  }

  @override
  Future<EauMineraleSettings?> getByLocalId(String localId) async {
    return getSettings();
  }
}

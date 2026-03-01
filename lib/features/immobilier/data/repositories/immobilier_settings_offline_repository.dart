
import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/immobilier_settings.dart';
import '../../domain/repositories/immobilier_settings_repository.dart';

class ImmobilierSettingsOfflineRepository extends OfflineRepository<ImmobilierSettings>
    implements ImmobilierSettingsRepository {
  ImmobilierSettingsOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.currentEnterpriseId,
  });

  final String currentEnterpriseId;

  @override
  String get collectionName => 'immobilier_settings';

  @override
  ImmobilierSettings fromMap(Map<String, dynamic> map) => ImmobilierSettings.fromMap(map);

  @override
  Map<String, dynamic> toMap(ImmobilierSettings entity) => entity.toMap();

  @override
  String getLocalId(ImmobilierSettings entity) => 'settings_${entity.enterpriseId}';

  @override
  String? getRemoteId(ImmobilierSettings entity) => getLocalId(entity);

  @override
  String? getEnterpriseId(ImmobilierSettings entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(ImmobilierSettings entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: localId,
      enterpriseId: entity.enterpriseId,
      moduleType: 'immobilier',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(ImmobilierSettings entity, {String? userId}) async {
    await saveToLocal(entity.copyWith(deletedAt: DateTime.now(), updatedAt: DateTime.now()));
  }

  @override
  Future<ImmobilierSettings?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: currentEnterpriseId,
      moduleType: 'immobilier',
    );
    if (record == null) return null;
    return fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<ImmobilierSettings>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((s) => !s.isDeleted)
        .toList();
  }

  // ImmobilierSettingsRepository implementation
  @override
  Future<ImmobilierSettings?> getSettings(String enterpriseId) async {
    return getByLocalId('settings_$enterpriseId');
  }

  @override
  Stream<ImmobilierSettings?> watchSettings(String enterpriseId) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'immobilier',
        )
        .map((rows) {
      final localId = 'settings_$enterpriseId';
      final row = rows.where((r) => r.localId == localId).firstOrNull;
      if (row == null) return null;
      return fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
    });
  }

  @override
  Future<void> saveSettings(ImmobilierSettings settings) async {
    await save(settings.copyWith(updatedAt: DateTime.now()));
  }
}

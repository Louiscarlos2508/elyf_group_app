
import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/boutique_settings.dart';
import '../../domain/repositories/boutique_settings_repository.dart';

class BoutiqueSettingsOfflineRepository extends OfflineRepository<BoutiqueSettings>
    implements BoutiqueSettingsRepository {
  BoutiqueSettingsOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.currentEnterpriseId,
  });

  final String currentEnterpriseId;

  @override
  String get collectionName => 'boutique_settings';

  @override
  BoutiqueSettings fromMap(Map<String, dynamic> map) => BoutiqueSettings.fromMap(map);

  @override
  Map<String, dynamic> toMap(BoutiqueSettings entity) => entity.toMap();

  @override
  String getLocalId(BoutiqueSettings entity) => 'settings_${entity.enterpriseId}';

  @override
  String? getRemoteId(BoutiqueSettings entity) => getLocalId(entity);

  @override
  String? getEnterpriseId(BoutiqueSettings entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(BoutiqueSettings entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: localId,
      enterpriseId: entity.enterpriseId,
      moduleType: 'boutique',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(BoutiqueSettings entity) async {
    // Soft delete if needed, but per-module settings usually aren't deleted
    await saveToLocal(entity.copyWith(deletedAt: DateTime.now()));
  }

  @override
  Future<BoutiqueSettings?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: currentEnterpriseId,
      moduleType: 'boutique',
    );
    if (record == null) return null;
    return fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<BoutiqueSettings>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((s) => !s.isDeleted)
        .toList();
  }

  // BoutiqueSettingsRepository implementation
  @override
  Future<BoutiqueSettings?> getSettings(String enterpriseId) async {
    return getByLocalId('settings_$enterpriseId');
  }

  @override
  Stream<BoutiqueSettings?> watchSettings(String enterpriseId) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'boutique',
        )
        .map((rows) {
      final localId = 'settings_$enterpriseId';
      final row = rows.where((r) => r.localId == localId).firstOrNull;
      if (row == null) return null;
      return fromMap(jsonDecode(row.dataJson) as Map<String, dynamic>);
    });
  }

  @override
  Future<void> saveSettings(BoutiqueSettings settings) async {
    await save(settings.copyWith(updatedAt: DateTime.now()));
  }
}

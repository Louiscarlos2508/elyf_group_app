import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/site_logistics_record.dart';
import '../../domain/repositories/site_logistics_record_repository.dart';

class GazSiteLogisticsRecordOfflineRepository extends OfflineRepository<GazSiteLogisticsRecord>
    implements GazSiteLogisticsRecordRepository {
  GazSiteLogisticsRecordOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'gaz_site_logistics_records';

  @override
  GazSiteLogisticsRecord fromMap(Map<String, dynamic> map) =>
      GazSiteLogisticsRecord.fromMap(map);

  @override
  Map<String, dynamic> toMap(GazSiteLogisticsRecord entity) => entity.toMap();

  @override
  String getLocalId(GazSiteLogisticsRecord entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(GazSiteLogisticsRecord entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(GazSiteLogisticsRecord entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(GazSiteLogisticsRecord entity, {String? userId}) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    
    // Récupérer le record existant pour préserver le remoteId si nécessaire
    final existingRecord = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final effectiveRemoteId = remoteId ?? existingRecord?.remoteId;

    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    await driftService.records.upsert(
      userId: userId ?? syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: effectiveRemoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(GazSiteLogisticsRecord entity, {String? userId}) async {
    await delete(entity);
  }

  @override
  Future<GazSiteLogisticsRecord?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (record == null) return null;
    final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
    map['id'] = record.localId;
    return fromMap(map);
  }

  @override
  Future<List<GazSiteLogisticsRecord>> getAllForEnterprise(String enterpriseId) async {
    final records = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return records.map((r) {
      final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
      map['id'] = r.localId;
      return fromMap(map);
    }).toList();
  }

  @override
  Future<List<GazSiteLogisticsRecord>> getRecords(String enterpriseId) async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Stream<List<GazSiteLogisticsRecord>> watchRecords(String enterpriseId) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) => rows.map((r) {
              final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
              map['id'] = r.localId;
              return fromMap(map);
            }).toList());
  }

  @override
  Future<GazSiteLogisticsRecord?> getRecordBySiteId(String enterpriseId, String siteId) async {
    final all = await getRecords(enterpriseId);
    try {
      return all.firstWhere((r) => r.siteId == siteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecord(GazSiteLogisticsRecord record) async {
    await save(record.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Stream<GazSiteLogisticsRecord?> watchRecordBySiteId(String enterpriseId, String siteId) {
    return watchRecords(enterpriseId).map((list) {
      try {
        return list.firstWhere((r) => r.siteId == siteId);
      } catch (_) {
        return null;
      }
    });
  }
}

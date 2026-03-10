import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/pos_remittance.dart';
import '../../domain/repositories/pos_remittance_repository.dart';

class GazPOSRemittanceOfflineRepository extends OfflineRepository<GazPOSRemittance>
    implements GazPOSRemittanceRepository {
  GazPOSRemittanceOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'gaz_pos_remittances';

  @override
  GazPOSRemittance fromMap(Map<String, dynamic> map) =>
      GazPOSRemittance.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(GazPOSRemittance entity) => entity.toMap();

  @override
  String getLocalId(GazPOSRemittance entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(GazPOSRemittance entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(GazPOSRemittance entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(GazPOSRemittance entity, {String? userId}) async {
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
  Future<void> deleteFromLocal(GazPOSRemittance entity, {String? userId}) async {
    await delete(entity);
  }

  @override
  Future<GazPOSRemittance?> getByLocalId(String localId) async {
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
  Future<List<GazPOSRemittance>> getAllForEnterprise(String enterpriseId) async {
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
  Future<List<GazPOSRemittance>> getRemittances(
    String enterpriseId, {
    String? posId,
    RemittanceStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await getAllForEnterprise(enterpriseId);
    return all.where((r) {
      if (posId != null && r.posId != posId) return false;
      if (status != null && r.status != status) return false;
      if (from != null && r.remittanceDate.isBefore(from)) return false;
      if (to != null && r.remittanceDate.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.remittanceDate.compareTo(a.remittanceDate));
  }

  @override
  Stream<List<GazPOSRemittance>> watchRemittances(
    String enterpriseId, {
    String? posId,
    RemittanceStatus? status,
    DateTime? from,
    DateTime? to,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final items = rows.map((r) {
            final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
            map['id'] = r.localId;
            return fromMap(map);
          }).toList();

          return items.where((r) {
            if (posId != null && r.posId != posId) return false;
            if (status != null && r.status != status) return false;
            if (from != null && r.remittanceDate.isBefore(from)) return false;
            if (to != null && r.remittanceDate.isAfter(to)) return false;
            return true;
          }).toList()
            ..sort((a, b) => b.remittanceDate.compareTo(a.remittanceDate));
        });
  }

  @override
  Future<GazPOSRemittance?> getRemittanceById(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<String> createRemittance(GazPOSRemittance remittance) async {
    final localId = getLocalId(remittance);
    final entity = remittance.copyWith(id: localId, createdAt: DateTime.now());
    await save(entity);
    return localId;
  }

  @override
  Future<void> updateRemittance(GazPOSRemittance remittance) async {
    await save(remittance.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> updateStatus(String id, RemittanceStatus status, {String? validatedBy}) async {
    final remittance = await getRemittanceById(id);
    if (remittance != null) {
      await save(remittance.copyWith(
        status: status,
        validatedBy: validatedBy,
        validatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> deleteRemittance(String id) async {
    final remittance = await getRemittanceById(id);
    if (remittance != null) {
      await delete(remittance);
    }
  }
}

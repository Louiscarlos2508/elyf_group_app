import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/stock_transfer.dart';
import '../../domain/repositories/stock_transfer_repository.dart';

class StockTransferOfflineRepository extends OfflineRepository<StockTransfer>
    implements StockTransferRepository {
  StockTransferOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.currentEnterpriseId,
  });

  final String currentEnterpriseId;

  @override
  String get collectionName => 'stock_transfers';

  @override
  StockTransfer fromMap(Map<String, dynamic> map) => StockTransfer.fromMap(map);

  @override
  Map<String, dynamic> toMap(StockTransfer entity) => entity.toMap();

  @override
  String getLocalId(StockTransfer entity) => entity.id;

  @override
  String? getRemoteId(StockTransfer entity) =>
      LocalIdGenerator.isLocalId(entity.id) ? null : entity.id;

  @override
  String? getEnterpriseId(StockTransfer entity) => entity.fromEnterpriseId;

  @override
  Future<void> saveToLocal(StockTransfer entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: entity.fromEnterpriseId,
      moduleType: 'gaz',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(StockTransfer entity) async {
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: getLocalId(entity),
      enterpriseId: entity.fromEnterpriseId,
      moduleType: 'gaz',
    );
  }

  @override
  Future<StockTransfer?> getByLocalId(String localId) async {
    final records = await driftService.records.listForCollection(
      collectionName: collectionName,
      moduleType: 'gaz',
    );
    final record = records.where((r) => r.localId == localId).firstOrNull;
    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    if (map == null) return null;
    return fromMap(map);
  }

  @override
  Future<List<StockTransfer>> getTransfers(String enterpriseId) async {
    final records = await driftService.records.listForCollection(
      collectionName: collectionName,
      moduleType: 'gaz',
    );
    return records
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .where((t) => t.fromEnterpriseId == enterpriseId || t.toEnterpriseId == enterpriseId)
        .toList();
  }

  @override
  Stream<List<StockTransfer>> watchTransfers(String enterpriseId) {
    // Note: We use listForCollection watch if we want all, but OfflineRecordDao doesn't have it.
    // However, we can use watchForEnterprises if we know the set of enterprises.
    // For now, let's watch everything in the collection and filter in Dart if possible.
    // But OfflineRecordDao doesn't have watchForCollection.
    
    // Let's use db.select(db.offlineRecords).watch() directly? 
    // No, let's stick to repositories patterns.
    
    // Actually, we can watch for ALL enterprises and filter.
    return (driftService.db.select(driftService.db.offlineRecords)
          ..where((t) => t.collectionName.equals(collectionName) & t.moduleType.equals('gaz')))
        .watch()
        .map((rows) => rows
            .map((r) => safeDecodeJson(r.dataJson, r.localId))
            .where((m) => m != null)
            .map((m) => fromMap(m!))
            .where((t) => t.fromEnterpriseId == enterpriseId || t.toEnterpriseId == enterpriseId)
            .toList());
  }

  @override
  Future<StockTransfer?> getTransferById(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<void> saveTransfer(StockTransfer transfer) async {
    await save(transfer);
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final transfer = await getByLocalId(id);
    if (transfer != null) {
      await delete(transfer);
    }
  }

  @override
  Future<List<StockTransfer>> getAllForEnterprise(String enterpriseId) {
    return getTransfers(enterpriseId);
  }
}

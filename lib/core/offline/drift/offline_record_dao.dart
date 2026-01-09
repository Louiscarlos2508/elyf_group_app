import 'package:drift/drift.dart';

import 'app_database.dart';

/// DAO for generic offline records stored as JSON.
class OfflineRecordDao {
  OfflineRecordDao(this._db);

  final AppDatabase _db;

  Future<void> upsert({
    required String collectionName,
    required String localId,
    required String enterpriseId,
    required String moduleType,
    required String dataJson,
    String? remoteId,
    DateTime? localUpdatedAt,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.offlineRecords).insert(
          OfflineRecordsCompanion.insert(
            collectionName: collectionName,
            localId: localId,
            enterpriseId: enterpriseId,
            moduleType: Value(moduleType),
            dataJson: dataJson,
            localUpdatedAt: localUpdatedAt ?? now,
            remoteId: Value(remoteId),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<OfflineRecord?> findByLocalId({
    required String collectionName,
    required String localId,
    required String enterpriseId,
    required String moduleType,
  }) {
    return (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType) &
                t.localId.equals(localId),
          ))
        .getSingleOrNull();
  }

  Future<OfflineRecord?> findByRemoteId({
    required String collectionName,
    required String remoteId,
    required String enterpriseId,
    required String moduleType,
  }) {
    return (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType) &
                t.remoteId.equals(remoteId),
          ))
        .getSingleOrNull();
  }

  Future<List<OfflineRecord>> listForEnterprise({
    required String collectionName,
    required String enterpriseId,
    required String moduleType,
  }) {
    return (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)]))
        .get();
  }

  /// List records for an enterprise with pagination support (LIMIT/OFFSET).
  /// 
  /// Returns a paginated list of records ordered by localUpdatedAt descending.
  Future<List<OfflineRecord>> listForEnterprisePaginated({
    required String collectionName,
    required String enterpriseId,
    required String moduleType,
    int limit = 50,
    int offset = 0,
  }) {
    return (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Count records for an enterprise.
  /// 
  /// Useful for pagination to know total number of records.
  Future<int> countForEnterprise({
    required String collectionName,
    required String enterpriseId,
    required String moduleType,
  }) async {
    // Use listForEnterprise and count in memory as a workaround for selectOnly where clause issues
    final records = await listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return records.length;
  }

  Future<void> deleteByLocalId({
    required String collectionName,
    required String localId,
    required String enterpriseId,
    required String moduleType,
  }) async {
    await (_db.delete(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType) &
                t.localId.equals(localId),
          ))
        .go();
  }

  Future<void> deleteByRemoteId({
    required String collectionName,
    required String remoteId,
    required String enterpriseId,
    required String moduleType,
  }) async {
    await (_db.delete(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType) &
                t.remoteId.equals(remoteId),
          ))
        .go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.offlineRecords).go();
  }

  Future<void> clearEnterprise(String enterpriseId) async {
    await (_db.delete(_db.offlineRecords)
          ..where((t) => t.enterpriseId.equals(enterpriseId)))
        .go();
  }

  /// Updates the remote ID for a record after successful sync.
  Future<void> updateRemoteId({
    required String collectionName,
    required String localId,
    required String remoteId,
    DateTime? serverUpdatedAt,
  }) async {
    await (_db.update(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.localId.equals(localId),
          ))
        .write(
      OfflineRecordsCompanion(
        remoteId: Value(remoteId),
        localUpdatedAt: Value(serverUpdatedAt ?? DateTime.now()),
      ),
    );
  }
}



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
    String? userId,
    String? remoteId,
    DateTime? localUpdatedAt,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.offlineRecords)
        .insert(
          OfflineRecordsCompanion.insert(
            collectionName: collectionName,
            localId: localId,
            enterpriseId: enterpriseId,
            moduleType: Value(moduleType),
            dataJson: dataJson,
            userId: Value(userId),
            localUpdatedAt: localUpdatedAt ?? now,
            remoteId: Value(remoteId),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> upsertAll(List<OfflineRecordsCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAll(
        _db.offlineRecords,
        companions,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Returns the most recently updated record when duplicates exist.
  Future<OfflineRecord?> findByLocalId({
    required String collectionName,
    required String localId,
    required String enterpriseId,
    required String moduleType,
  }) async {
    final list = await (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType) &
                t.localId.equals(localId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(1))
        .get();
    return list.isEmpty ? null : list.first;
  }

  /// Returns the most recently updated record when duplicates exist.
  Future<OfflineRecord?> findByRemoteId({
    required String collectionName,
    required String remoteId,
    required String enterpriseId,
    required String moduleType,
  }) async {
    final list = await (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.moduleType.equals(moduleType) &
                t.remoteId.equals(remoteId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(1))
        .get();
    return list.isEmpty ? null : list.first;
  }

  /// Like [findByRemoteId] but ignores moduleType — used during sync to find
  /// records that may have been saved with an empty/wrong moduleType.
  Future<OfflineRecord?> findByRemoteIdAny({
    required String collectionName,
    required String remoteId,
    required String enterpriseId,
  }) async {
    final list = await (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.remoteId.equals(remoteId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(1))
        .get();
    return list.isEmpty ? null : list.first;
  }

  /// Like [findByLocalId] but ignores moduleType — used during sync to find
  /// records that may have been saved with an empty/wrong moduleType.
  Future<OfflineRecord?> findByLocalIdAny({
    required String collectionName,
    required String localId,
    required String enterpriseId,
  }) async {
    final list = await (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.equals(enterpriseId) &
                t.localId.equals(localId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(1))
        .get();
    return list.isEmpty ? null : list.first;
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

  Stream<List<OfflineRecord>> watchForEnterprise({
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
        .watch();
  }

  Future<List<OfflineRecord>> listForEnterprises({
    required String collectionName,
    required List<String> enterpriseIds,
    required String moduleType,
  }) {
    return (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.isIn(enterpriseIds) &
                t.moduleType.equals(moduleType),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)]))
        .get();
  }

  Stream<List<OfflineRecord>> watchForEnterprises({
    required String collectionName,
    required List<String> enterpriseIds,
    required String moduleType,
  }) {
    return (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.enterpriseId.isIn(enterpriseIds) &
                t.moduleType.equals(moduleType),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)]))
        .watch();
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

  /// Deletes a single record by its auto-increment primary key.
  /// Used during sync to remove stale records with incorrect moduleType.
  Future<void> deleteById(int id) async {
    await (_db.delete(_db.offlineRecords)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> deleteByLocalId({
    required String collectionName,
    required String localId,
    required String enterpriseId,
    required String moduleType,
  }) async {
    await (_db.delete(_db.offlineRecords)..where(
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
    await (_db.delete(_db.offlineRecords)..where(
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
    await (_db.delete(
      _db.offlineRecords,
    )..where((t) => t.enterpriseId.equals(enterpriseId))).go();
  }

  /// List all records for a collection and optionally module type, regardless of enterpriseId.
  ///
  /// Useful for retrieving all points of sale across all enterprises.
  Future<List<OfflineRecord>> listForCollection({
    required String collectionName,
    String? moduleType,
  }) {
    final query = _db.select(_db.offlineRecords)
      ..where((t) => t.collectionName.equals(collectionName));
    
    if (moduleType != null) {
      query.where((t) => t.moduleType.equals(moduleType));
    }
    
    return (query..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])).get();
  }

  /// Watches all records for a collection, regardless of enterpriseId.
  Stream<List<OfflineRecord>> watchForCollection({
    required String collectionName,
    String? moduleType,
  }) {
    final query = _db.select(_db.offlineRecords)
      ..where((t) => t.collectionName.equals(collectionName));
    
    if (moduleType != null) {
      query.where((t) => t.moduleType.equals(moduleType));
    }
    
    return (query..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])).watch();
  }

  /// Finds a record by its remote ID within a collection, regardless of enterpriseId.
  Future<OfflineRecord?> findInCollectionByRemoteId({
    required String collectionName,
    required String remoteId,
  }) async {
    final list = await (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.remoteId.equals(remoteId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(1))
        .get();
    return list.isEmpty ? null : list.first;
  }

  /// Finds a record by its local ID within a collection, regardless of enterpriseId.
  Future<OfflineRecord?> findInCollectionByLocalId({
    required String collectionName,
    required String localId,
  }) async {
    final list = await (_db.select(_db.offlineRecords)
          ..where(
            (t) =>
                t.collectionName.equals(collectionName) &
                t.localId.equals(localId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localUpdatedAt)])
          ..limit(1))
        .get();
    return list.isEmpty ? null : list.first;
  }

  /// Updates the remote ID for a record after successful sync.
  ///
  /// Filtre par [enterpriseId] et [moduleType] lorsqu'ils sont fournis pour
  /// éviter de modifier des lignes d'une autre entreprise/module.
  Future<void> updateRemoteId({
    required String collectionName,
    required String localId,
    required String remoteId,
    DateTime? serverUpdatedAt,
    String? enterpriseId,
    String? moduleType,
  }) async {
    await (_db.update(_db.offlineRecords)..where((t) {
          var e = t.collectionName.equals(collectionName) &
              t.localId.equals(localId);
          if (enterpriseId != null && enterpriseId.isNotEmpty) {
            e = e & t.enterpriseId.equals(enterpriseId);
          }
          if (moduleType != null && moduleType.isNotEmpty) {
            e = e & t.moduleType.equals(moduleType);
          }
          return e;
        }))
        .write(
          OfflineRecordsCompanion(
            remoteId: Value(remoteId),
            localUpdatedAt: Value(serverUpdatedAt ?? DateTime.now()),
          ),
        );
  }
}

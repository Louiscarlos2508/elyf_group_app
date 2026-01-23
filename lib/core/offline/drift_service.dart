import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import 'drift/app_database.dart';
import 'drift/offline_record_dao.dart';
import 'drift/sync_operation_dao.dart';

/// DriftService - local SQLite persistence via Drift.
///
/// Local storage implementation based on Drift (SQLite).
class DriftService {
  DriftService._();

  static DriftService? _instance;
  bool _initialized = false;

  AppDatabase? _db;
  OfflineRecordDao? _records;
  SyncOperationDao? _syncOperations;

  /// Singleton instance.
  static DriftService get instance {
    _instance ??= DriftService._();
    return _instance!;
  }

  bool get isInitialized => _initialized;

  /// Access to the underlying Drift database.
  AppDatabase get db {
    final db = _db;
    if (db == null) {
      throw StateError(
        'DriftService not initialized. Call initialize() first.',
      );
    }
    return db;
  }

  /// DAO used by offline repositories.
  OfflineRecordDao get records {
    final dao = _records;
    if (dao == null) {
      throw StateError(
        'DriftService not initialized. Call initialize() first.',
      );
    }
    return dao;
  }

  /// DAO used for sync operations queue.
  SyncOperationDao get syncOperations {
    final dao = _syncOperations;
    if (dao == null) {
      throw StateError(
        'DriftService not initialized. Call initialize() first.',
      );
    }
    return dao;
  }

  static const int currentVersion = 1;

  Future<void> initialize() async {
    if (_initialized) {
      developer.log('DriftService already initialized', name: 'offline.drift');
      return;
    }

    _db = AppDatabase();
    _records = OfflineRecordDao(_db!);
    _syncOperations = SyncOperationDao(_db!);
    _initialized = true;

    developer.log('DriftService initialized', name: 'offline.drift');
  }

  Future<void> clearAll() async {
    await records.clearAll();
  }

  Future<void> clearEnterpriseData(String enterpriseId) async {
    await records.clearEnterprise(enterpriseId);
    await syncOperations.clearEnterprise(enterpriseId);
  }

  Future<int> getPendingSyncCount() async {
    return await _syncOperations?.countPending() ?? 0;
  }

  Future<Map<String, int>> getStats() async {
    final countExpr = db.offlineRecords.id.count();
    final row = await (db.selectOnly(
      db.offlineRecords,
    )..addColumns([countExpr])).getSingle();
    final total = row.read(countExpr) ?? 0;
    return {'offlineRecords': total};
  }

  Future<void> close() async {
    _initialized = false;
    await _db?.close();
    _db = null;
    _records = null;
    _syncOperations = null;
    developer.log('DriftService closed', name: 'offline.drift');
  }

  static Future<void> dispose() async {
    await _instance?.close();
    _instance = null;
  }
}

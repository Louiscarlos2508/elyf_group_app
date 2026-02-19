import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/offline/drift/app_database.dart';
import '../../domain/entities/gaz_session.dart';
import '../../domain/repositories/session_repository.dart';

class GazSessionOfflineRepository implements GazSessionRepository {
  GazSessionOfflineRepository(this._db);

  final AppDatabase _db;
  static const String _collectionName = 'gaz_sessions';

  @override
  Future<List<GazSession>> getSessions({DateTime? from, DateTime? to}) async {
    final query = _db.select(_db.offlineRecords)
      ..where((t) => t.collectionName.equals(_collectionName));

    final results = await query.get();
    return results
        .map((r) => GazSession.fromMap(jsonDecode(r.dataJson)))
        .where((s) {
      if (from != null && (s.date?.isBefore(from) ?? false)) return false;
      if (to != null && (s.date?.isAfter(to) ?? false)) return false;
      return true;
    }).toList();
  }

  @override
  Stream<List<GazSession>> watchSessions({DateTime? from, DateTime? to}) {
    return (_db.select(_db.offlineRecords)
          ..where((t) => t.collectionName.equals(_collectionName)))
        .watch()
        .map((results) {
      return results
          .map((r) => GazSession.fromMap(jsonDecode(r.dataJson)))
          .where((s) {
        if (from != null && (s.date?.isBefore(from) ?? false)) return false;
        if (to != null && (s.date?.isAfter(to) ?? false)) return false;
        return true;
      }).toList();
    });
  }

  @override
  Future<GazSession?> getSessionById(String id) async {
    final record = await (_db.select(_db.offlineRecords)
          ..where((t) => t.collectionName.equals(_collectionName))
          ..where((t) => t.localId.equals(id)))
        .getSingleOrNull();

    if (record == null) return null;
    return GazSession.fromMap(jsonDecode(record.dataJson));
  }

  @override
  Future<void> saveSession(GazSession session) async {
    final now = DateTime.now();
    await _db.into(_db.offlineRecords).insertOnConflictUpdate(
          OfflineRecordsCompanion(
            collectionName: const Value(_collectionName),
            localId: Value(session.id),
            enterpriseId: Value(session.enterpriseId),
            moduleType: const Value('gaz'),
            dataJson: Value(jsonEncode(session.toMap())),
            localUpdatedAt: Value(now),
          ),
        );

    // Queue sync operation
    await _db.into(_db.syncOperations).insert(
          SyncOperationsCompanion.insert(
            operationType: 'create',
            collectionName: _collectionName,
            documentId: session.id,
            enterpriseId: session.enterpriseId,
            payload: Value(jsonEncode(session.toMap())),
            createdAt: now,
            localUpdatedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteSession(String id) async {
    final session = await getSessionById(id);
    if (session == null) return;

    await (_db.delete(_db.offlineRecords)
          ..where((t) => t.collectionName.equals(_collectionName))
          ..where((t) => t.localId.equals(id)))
        .go();

    await _db.into(_db.syncOperations).insert(
          SyncOperationsCompanion.insert(
            operationType: 'delete',
            collectionName: _collectionName,
            documentId: id,
            enterpriseId: session.enterpriseId,
            createdAt: DateTime.now(),
            localUpdatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<GazSession?> getSessionByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final sessions = await getSessions(from: dayStart, to: dayStart.add(const Duration(days: 1)));
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<GazSession?> getActiveSession(String enterpriseId) async {
    final query = _db.select(_db.offlineRecords)
      ..where((t) => t.collectionName.equals(_collectionName))
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    final results = await query.get();
    for (final record in results) {
      final session = GazSession.fromMap(jsonDecode(record.dataJson));
      if (session.isOpen) return session;
    }
    return null;
  }
}

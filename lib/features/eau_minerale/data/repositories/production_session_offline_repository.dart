import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/collection_names.dart';
import '../../domain/entities/machine_material_usage.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/repositories/production_session_repository.dart';

/// Offline-first repository for ProductionSession entities.
class ProductionSessionOfflineRepository
    extends OfflineRepository<ProductionSession>
    implements ProductionSessionRepository {
  ProductionSessionOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    this.moduleType = 'eau_minerale',
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => CollectionNames.productionSessions;

  @override
  ProductionSession fromMap(Map<String, dynamic> map) =>
      ProductionSession.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(ProductionSession entity) => entity.toMap();

  @override
  String getLocalId(ProductionSession entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(ProductionSession entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(ProductionSession entity) => enterpriseId;

  @override
  Future<void> saveToLocal(ProductionSession entity, {String? userId}) async {
    String localId;
    final remoteId = getRemoteId(entity);

    if (remoteId != null) {
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      
      if (existingRecord != null) {
        localId = existingRecord.localId;
      } else {
        localId = LocalIdGenerator.generate();
      }
    } else {
      localId = getLocalId(entity);
    }

    final map = toMap(entity);
    map['localId'] = localId; 
    
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(ProductionSession entity, {String? userId}) async {
    final deletedSession = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedSession, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted production session: ${entity.id}',
      name: 'ProductionSessionOfflineRepository',
    );
  }

  @override
  Future<ProductionSession?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final session = fromMap(
        jsonDecode(byRemote.dataJson) as Map<String, dynamic>,
      );
      if (session.isDeleted) return null;
      return _mergeWithLocalIfAvailable(session);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final session = fromMap(
      jsonDecode(byLocal.dataJson) as Map<String, dynamic>,
    );
    if (session.isDeleted) return null;
    return _mergeWithLocalIfAvailable(session);
  }

  Future<ProductionSession> _mergeWithLocalIfAvailable(
    ProductionSession session,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final key = _sessionKey(session);
    for (final r in rows) {
      if (r.remoteId != null && r.remoteId!.isNotEmpty) continue;
      if (r.localId == session.id) continue;
      
      try {
        final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
        final other = fromMap(map);
        if (_sessionKey(other) == key) {
          return session.mergeWith(other);
        }
      } catch (_) {
        continue;
      }
    }
    return session;
  }

  @override
  Future<List<ProductionSession>> getAllForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    final sessions = rows
        .map((row) => safeDecodeJson(row.dataJson, row.localId))
        .where((map) => map != null)
        .map((map) => fromMap(map!))
        .where((session) => !session.isDeleted)
        .toList();

    var deduped = deduplicateByRemoteId(sessions);
    deduped = _mergeLocalMaterialsIntoSync(deduped);
    return deduplicateIntelligently(deduped);
  }

  static String _sessionKey(ProductionSession s) {
    final d = s.date.toUtc();
    final h = s.heureDebut.toUtc();
    return '${d.year}-${d.month}-${d.day}-${h.hour}-${h.minute}';
  }

  List<ProductionSession> _mergeLocalMaterialsIntoSync(
    List<ProductionSession> sessions,
  ) {
    final localByKey = <String, ProductionSession>{};
    final syncList = <ProductionSession>[];

    for (final s in sessions) {
      final key = _sessionKey(s);
      if (getRemoteId(s) != null) {
        syncList.add(s);
      } else {
        final existing = localByKey[key];
        if (existing == null ||
            s.productionDays.length > existing.productionDays.length ||
            (s.updatedAt ?? s.createdAt ?? DateTime(0))
                .isAfter(existing.updatedAt ?? existing.createdAt ?? DateTime(0))) {
          localByKey[key] = s;
        }
      }
    }

    final merged = <ProductionSession>[];
    for (final sync in syncList) {
      final key = _sessionKey(sync);
      final local = localByKey[key];
      
      if (local != null) {
        merged.add(sync.mergeWith(local));
      } else {
        merged.add(sync);
      }
      localByKey.remove(key);
    }
    
    merged.addAll(localByKey.values);
    return merged;
  }

  @override
  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var allSessions = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        allSessions = allSessions
            .where(
              (s) =>
                  s.date.isAfter(startDate) ||
                  s.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        allSessions = allSessions
            .where(
              (s) =>
                  s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      allSessions.sort((a, b) => b.date.compareTo(a.date));

      return allSessions;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      throw appException;
    }
  }

  @override
  Stream<List<ProductionSession>> watchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          var sessions = rows
              .map((row) => safeDecodeJson(row.dataJson, row.localId))
              .where((map) => map != null)
              .map((map) => fromMap(map!))
              .where((session) => !session.isDeleted)
              .toList();

          if (startDate != null) {
            sessions = sessions
                .where(
                  (s) =>
                      s.date.isAfter(startDate) ||
                      s.date.isAtSameMomentAs(startDate),
                )
                .toList();
          }

          if (endDate != null) {
            sessions = sessions
                .where(
                  (s) =>
                      s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate),
                )
                .toList();
          }

          sessions.sort((a, b) => b.date.compareTo(a.date));

          var deduped = deduplicateByRemoteId(sessions);
          deduped = _mergeLocalMaterialsIntoSync(deduped);
          return deduplicateIntelligently(deduped);
        });
  }

  @override
  Future<ProductionSession?> fetchSessionById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      throw appException;
    }
  }

  @override
  Future<ProductionSession> createSession(ProductionSession session) async {
    try {
      final existingSessions = await getAllForEnterprise(enterpriseId);
      final key = _sessionKey(session);
      
      for (final existing in existingSessions) {
        if (_sessionKey(existing) == key) {
          return existing;
        }
      }

      final localId = session.id.isNotEmpty ? session.id : 'local_prod_$key';
      final sessionWithLocalId = session.copyWith(
        id: localId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(sessionWithLocalId);
      return sessionWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      throw appException;
    }
  }

  @override
  Future<ProductionSession> updateSession(ProductionSession session) async {
    try {
      final updatedSession = session.copyWith(updatedAt: DateTime.now());
      await save(updatedSession);
      return updatedSession;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      throw appException;
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      final session = await fetchSessionById(id);
      if (session != null) {
        await delete(session);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      throw appException;
    }
  }

  @override
  Future<MachineMaterialUsage?> fetchLastUnfinishedMaterialForMachine(String machineId) async {
    try {
      int offset = 0;
      const int limit = 10;
      bool continueFetching = true;

      while (continueFetching) {
        final rows = await driftService.records.listForEnterprisePaginated(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
          limit: limit,
          offset: offset,
        );

        if (rows.isEmpty) {
          continueFetching = false;
          break;
        }

        final sessions = rows
            .map((row) => safeDecodeJson(row.dataJson, row.localId))
            .where((map) => map != null)
            .map((map) => fromMap(map!))
            .where((session) => !session.isDeleted)
            .toList();

        for (final session in sessions) {
          for (final usage in session.machineMaterials) {
            if (usage.machineId == machineId && !usage.estFinie) {
              return usage;
            }
          }
        }

        if (rows.length < limit || offset > 100) {
          continueFetching = false;
        } else {
          offset += limit;
        }
      }

      return null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error finding last unfinished material for machine $machineId',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

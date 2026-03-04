import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
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
  });

  final String enterpriseId;

  @override
  String get collectionName => 'production_sessions';

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
      // Si c'est une session synchronisée (ID distant), on cherche son ID local existant
      // pour éviter de créer un doublon avec un nouveau ID local aléatoire.
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      
      if (existingRecord != null) {
        localId = existingRecord.localId;
      } else {
        // Pas encore de record local pour ce remoteId, on génère un nouvel ID
        localId = LocalIdGenerator.generate();
      }
    } else {
      // Si l'ID est déjà local (commence par local_), ou si pas de remoteId
      localId = getLocalId(entity);
    }

    final map = toMap(entity);
    map['localId'] = localId; // Assurer la cohérence dans le JSON stocké
    
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(ProductionSession entity, {String? userId}) async {
    // Soft-delete
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
      moduleType: 'eau_minerale',
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
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    final session = fromMap(
      jsonDecode(byLocal.dataJson) as Map<String, dynamic>,
    );
    if (session.isDeleted) return null;
    return _mergeWithLocalIfAvailable(session);
  }

  /// Tente de fusionner la session avec une version locale (sans remoteId)
  /// ayant la même date+heure début pour éviter la perte de données orphelines.
  Future<ProductionSession> _mergeWithLocalIfAvailable(
    ProductionSession session,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    final key = _sessionKey(session);
    for (final r in rows) {
      if (r.remoteId != null && r.remoteId!.isNotEmpty) continue;
      if (r.localId == session.id) continue;
      
      try {
        final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
        final other = fromMap(map);
        if (_sessionKey(other) == key) {
          // Fusion constructive
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
    AppLogger.debug(
      'Fetching all production sessions for enterprise: $enterpriseId (module: eau_minerale)',
      name: 'ProductionSessionOfflineRepository',
    );

    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );

    AppLogger.debug(
      'Found ${rows.length} records for $collectionName / $enterpriseId',
      name: 'ProductionSessionOfflineRepository',
    );

    final sessions = rows
        .map((row) => safeDecodeJson(row.dataJson, row.localId))
        .where((map) => map != null)
        .map((map) => fromMap(map!))
        .where((session) => !session.isDeleted)
        .toList();

    AppLogger.debug(
      'Successfully decoded ${sessions.length} sessions',
      name: 'ProductionSessionOfflineRepository',
    );

    var deduped = deduplicateByRemoteId(sessions);
    deduped = _mergeLocalBobinesIntoSync(deduped);
    // Couche de sécurité finale pour éviter les doublons logiques (date+heure identiques)
    return deduplicateIntelligently(deduped);
  }

  /// Clé pour matcher deux enregistrements de la même session (date + heure début).
  /// Utilise UTC pour éviter les décalages de fuseau horaire.
  static String _sessionKey(ProductionSession s) {
    final d = s.date.toUtc();
    final h = s.heureDebut.toUtc();
    return '${d.year}-${d.month}-${d.day}-${h.hour}-${h.minute}';
  }

  /// Fusionne les données des sessions locales (sans remoteId) dans les sessions
  /// sync (avec remoteId) pour éviter la perte de données (personnel, production).
  List<ProductionSession> _mergeLocalBobinesIntoSync(
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
        // Garder la version locale orpheline si elle a plus de données ou est plus récente
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
        // Utiliser la nouvelle méthode mergeWith pour une fusion robuste
        merged.add(sync.mergeWith(local));
      } else {
        merged.add(sync);
      }
      // Toujours retirer du map local si on a une session sync pour cette clé
      localByKey.remove(key);
    }
    
    // Ajouter les sessions locales qui n'ont pas d'équivalent remote
    merged.addAll(localByKey.values);
    return merged;
  }

  // ProductionSessionRepository interface implementation

  @override
  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug(
        'Fetching production sessions for enterprise: $enterpriseId',
        name: 'ProductionSessionOfflineRepository',
      );
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

      // Sort by date descending
      allSessions.sort((a, b) => b.date.compareTo(a.date));

      return allSessions;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching production sessions',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
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
          moduleType: 'eau_minerale',
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

          // Sort by date descending
          sessions.sort((a, b) => b.date.compareTo(a.date));

          var deduped = deduplicateByRemoteId(sessions);
          deduped = _mergeLocalBobinesIntoSync(deduped);
          return deduplicateIntelligently(deduped);
        });
  }

  @override
  Future<ProductionSession?> fetchSessionById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting production session: $id - ${appException.message}',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ProductionSession> createSession(ProductionSession session) async {
    try {
      // Vérifier si une session avec la même date et heure existe déjà
      final existingSessions = await getAllForEnterprise(enterpriseId);
      final key = _sessionKey(session);
      
      for (final existing in existingSessions) {
        if (_sessionKey(existing) == key) {
          AppLogger.debug(
            'Session déjà existante pour la clé $key. Retourne la session existante.',
            name: 'ProductionSessionOfflineRepository',
          );
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
      AppLogger.error(
        'Error creating production session: ${appException.message}',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
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
      AppLogger.error(
        'Error updating production session: ${session.id} - ${appException.message}',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
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
      AppLogger.error(
        'Error deleting production session: $id - ${appException.message}',
        name: 'ProductionSessionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';
import 'drift_service.dart';
import 'optimistic_ui.dart';
import 'security/data_sanitizer.dart';
import 'smart_deduplicator.dart';
import 'sync_manager.dart';
import 'sync_status.dart';

/// Base class for offline-first repositories with automatic sync queuing.
///
/// Provides:
/// - Local storage via Drift (SQLite)
/// - Automatic sync queue management
/// - Conflict detection and resolution
/// - Connectivity-aware sync triggering
/// - Optimistic UI support (optional)
abstract class OfflineRepository<T> with OptimisticUIRepositoryMixin<T> {
  OfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    this.enableAutoSync = true,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;

  /// Whether to automatically queue sync operations on save/delete.
  final bool enableAutoSync;

  String get collectionName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);
  String getLocalId(T entity);
  String? getRemoteId(T entity);
  String? getEnterpriseId(T entity);

  bool get isOnline => connectivityService.isOnline;

  /// Saves an entity to local storage and queues for sync.
  ///
  /// Ne lance pas d'exception si la sauvegarde locale échoue (erreur SQLite),
  /// pour permettre à l'opération de continuer. L'entité sera récupérée depuis
  /// Firestore lors de la prochaine synchronisation.
  @override
  Future<void> save(T entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);
    
    // Sanitizer et valider les données avant de les sauvegarder
    final rawData = toMap(entity);
    final sanitizedData = DataSanitizer.sanitizeMap(rawData);
    
    // Valider la taille avant de continuer
    try {
      DataSanitizer.validateJsonSize(jsonEncode(sanitizedData));
    } on DataSizeException catch (e) {
      throw ValidationException(
        'Données trop volumineuses pour $collectionName/$localId: ${e.message}',
        'DATA_SIZE_EXCEEDED',
      );
    }
    
    final data = sanitizedData;

    AppLogger.debug(
      'OfflineRepository.save: $collectionName/$localId',
      name: 'offline.repository',
    );

    // Utiliser une transaction pour garantir l'atomicité de l'opération
    // (saveToLocal + queue sync doivent être atomiques)
    try {
      await driftService.db.transaction(() async {
        // Save to local storage first
        try {
          await saveToLocal(entity);
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Error saving to local storage (entity exists in Firestore, will be synced later): ${appException.message}',
            name: 'offline.repository',
            error: e,
            stackTrace: stackTrace,
          );
          // Ne pas rethrow - permet à l'opération de continuer même si Drift échoue
          // L'entité sera récupérée depuis Firestore lors de la prochaine synchronisation
        }

        // Queue sync operation if auto-sync is enabled
        // Même si la sauvegarde locale a échoué, on peut quand même queue la sync
        if (enableAutoSync) {
          try {
            if (remoteId != null && remoteId.isNotEmpty) {
              // Update existing remote document
              await syncManager.queueUpdate(
                collectionName: collectionName,
                localId: localId,
                remoteId: remoteId,
                data: data,
                enterpriseId: enterpriseId,
              );
            } else {
              // Create new document
              await syncManager.queueCreate(
                collectionName: collectionName,
                localId: localId,
                data: data,
                enterpriseId: enterpriseId,
              );
            }
          } catch (e, stackTrace) {
            final appException = ErrorHandler.instance.handleError(e, stackTrace);
            AppLogger.warning(
              'Error queueing sync operation: ${appException.message}',
              name: 'offline.repository',
              error: e,
              stackTrace: stackTrace,
            );
            // Ne pas rethrow - la sync se fera plus tard
          }
        }
      });
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error in transaction for save operation: ${appException.message}',
        name: 'offline.repository',
        error: e,
        stackTrace: stackTrace,
      );
      // Rethrow pour que l'appelant puisse gérer l'erreur
      rethrow;
    }
  }

  Future<void> saveToLocal(T entity);

  /// Cherche le localId existant d'une entité avant de sauvegarder.
  ///
  /// Cette méthode évite les duplications en cherchant l'entité existante
  /// de plusieurs façons avant de générer un nouveau localId.
  ///
  /// Ordre de recherche:
  /// 1. Si l'ID de l'entité commence par 'local_', retourne cet ID directement
  /// 2. Cherche par remoteId si disponible
  /// 3. Cherche par l'ID de l'entité via getByLocalId
  ///
  /// Retourne le localId existant si trouvé, sinon null.
  ///
  /// [moduleType] est requis pour la recherche dans la base de données.
  @protected
  Future<String?> findExistingLocalId(
    T entity, {
    required String moduleType,
  }) async {
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);
    
    // 1. Chercher d'abord par remoteId si disponible
    // C'est le moyen le plus sûr d'identifier une même entité provenant du serveur
    if (remoteId != null && remoteId.isNotEmpty) {
      final byRemote = await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId ?? '',
        moduleType: moduleType,
      );
      if (byRemote != null) {
        AppLogger.debug(
          'Entité existante trouvée par remoteId: $remoteId -> localId: ${byRemote.localId}',
          name: 'OfflineRepository.findExistingLocalId',
        );
        return byRemote.localId;
      }
    }

    final entityId = getLocalId(entity);
    
    // 2. Si l'ID commence par 'local_', c'est déjà un localId
    if (entityId.startsWith('local_')) {
      return entityId;
    }
    
    // Chercher par l'ID de l'entité (peut être un localId ou autre)
    try {
      final existing = await getByLocalId(entityId);
      if (existing != null) {
        // Récupérer le localId depuis la base de données
        final rows = await driftService.records.listForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId ?? '',
          moduleType: moduleType,
        );
        for (final row in rows) {
          try {
            final map = safeDecodeJson(row.dataJson, row.localId);
            if (map == null) continue;
            final entityFromMap = fromMap(map);
            // Comparer les entités (utiliser l'ID ou d'autres champs clés selon le type)
            if (getLocalId(entityFromMap) == entityId || 
                getRemoteId(entityFromMap) == remoteId) {
              AppLogger.debug(
                'Entité existante trouvée par ID: $entityId -> localId: ${row.localId}',
                name: 'OfflineRepository.findExistingLocalId',
              );
              return row.localId;
            }
          } catch (_) {
            continue;
          }
        }
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Erreur lors de la recherche de l\'entité existante: ${appException.message}',
        name: 'OfflineRepository.findExistingLocalId',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    return null;
  }

  /// Deletes an entity from local storage and queues delete for sync.
  @override
  Future<void> delete(T entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final enterpriseId = getEnterpriseId(entity);

    AppLogger.debug(
      'OfflineRepository.delete: $collectionName/$localId',
      name: 'offline.repository',
    );

    // Delete from local storage first
    await deleteFromLocal(entity);

    // Queue sync operation if auto-sync is enabled and has remote ID
    if (enableAutoSync && remoteId != null && remoteId.isNotEmpty) {
      await syncManager.queueDelete(
        collectionName: collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
      );
    }
  }

  Future<void> deleteFromLocal(T entity);

  /// Décode de manière sécurisée un JSON depuis Drift.
  ///
  /// Gère les données corrompues en retournant null et en loggant l'erreur.
  /// Les repositories doivent utiliser cette méthode au lieu de jsonDecode directement.
  @protected
  Map<String, dynamic>? safeDecodeJson(String? jsonString, String recordId) {
    if (jsonString == null || jsonString.isEmpty) {
      AppLogger.info(
        'Empty JSON string for $collectionName/$recordId',
        name: 'offline.repository',
      );
      return null;
    }

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Corrupted data in $collectionName/$recordId: ${appException.message}',
        name: 'offline.repository',
        error: e,
        stackTrace: stackTrace,
      );
      // Retourner null pour indiquer que les données sont corrompues
      // L'appelant devra gérer ce cas (retourner null ou une liste vide)
      return null;
    }
  }

  Future<T?> getByLocalId(String localId);

  Future<List<T>> getAllForEnterprise(String enterpriseId);

  /// Déduplique intelligemment une liste d'entités en utilisant SmartDeduplicator.
  ///
  /// Détecte les doublons même avec des IDs différents en comparant les champs clés
  /// et fusionne intelligemment les données en prenant les valeurs les plus récentes.
  ///
  /// Cette méthode est optionnelle et peut être utilisée pour améliorer la qualité
  /// des données en détectant les doublons basés sur le contenu plutôt que sur les IDs.
  List<T> deduplicateIntelligently(List<T> entities) {
    if (entities.isEmpty) {
      return entities;
    }

    final deduplicator = SmartDeduplicator();
    
    // Convertir les entités en maps pour la déduplication
    final entityMaps = entities.map((e) => toMap(e)).toList();
    
    // Dédupliquer
    final deduplicatedMaps = deduplicator.deduplicate(
      collectionName: collectionName,
      entities: entityMaps,
    );
    
    // Reconvertir en entités
    return deduplicatedMaps.map((map) => fromMap(map)).toList();
  }

  /// Déduplique une liste d'entités par remoteId.
  ///
  /// Évite les doublons qui peuvent survenir si ModuleRealtimeSyncService
  /// et le repository utilisent des localId différents pour la même entité.
  /// Garde l'entité la plus récente pour chaque remoteId.
  ///
  /// Les entités sans remoteId (créées localement) sont toutes conservées.
  ///
  /// Note: Cette méthode est destinée à être utilisée uniquement par les
  /// sous-classes d'OfflineRepository.
  List<T> deduplicateByRemoteId(List<T> entities) {
    final Map<String, T> entitiesByRemoteId = {};
    final List<T> entitiesWithoutRemoteId = [];

    for (final entity in entities) {
      final remoteId = getRemoteId(entity);

      if (remoteId != null) {
        // Si on n'a pas encore vu ce remoteId, l'ajouter
        // (les entités sont déjà triées par localUpdatedAt descendant
        // dans listForEnterprise, donc le premier est le plus récent)
        if (!entitiesByRemoteId.containsKey(remoteId)) {
          entitiesByRemoteId[remoteId] = entity;
        }
        // Sinon, ignorer ce doublon (on a déjà le plus récent)
      } else {
        // Entités sans remoteId (créées localement) : garder toutes
        entitiesWithoutRemoteId.add(entity);
      }
    }

    // Combiner les entités dédupliquées et celles sans remoteId
    return [...entitiesByRemoteId.values, ...entitiesWithoutRemoteId];
  }

  /// Marks an entity as synced with the remote server.
  Future<void> markSynced({
    required String localId,
    required String remoteId,
    DateTime? serverUpdatedAt,
  }) async {
    AppLogger.debug(
      'markSynced: $collectionName/$localId -> $remoteId',
      name: 'offline.repository',
    );

    // Update the record with the remote ID
    await driftService.records.updateRemoteId(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      serverUpdatedAt: serverUpdatedAt,
    );
  }

  /// Gets the sync state for an entity.
  Future<SyncState> getSyncState(String localId) async {
    final pendingOps = await syncManager.getPendingForCollection(
      collectionName,
    );
    final hasPending = pendingOps.any((op) => op.documentId == localId);
    return hasPending ? SyncState.pending : SyncState.synced;
  }

  /// Gets all entities pending sync.
  Future<List<SyncMetadata>> getPendingSync() async {
    final pendingOps = await syncManager.getPendingForCollection(
      collectionName,
    );
    return pendingOps
        .map(
          (op) => SyncMetadata(
            localId: op.documentId,
            collectionName: op.collectionName,
            operationType: op.operationType,
            createdAt: op.createdAt,
          ),
        )
        .toList();
  }
}


/// Utility for generating local IDs.
class LocalIdGenerator {
  LocalIdGenerator._();

  static final _random = Random();

  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1000000).toRadixString(36);
    return 'local_${timestamp}_$randomPart';
  }

  static bool isLocalId(String id) {
    return id.startsWith('local_');
  }
}

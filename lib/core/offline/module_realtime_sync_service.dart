import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'drift/app_database.dart';
import 'drift_service.dart';
import 'module_data_sync_service.dart';
import 'security/data_sanitizer.dart';
import 'sync_manager.dart';

/// Service pour la synchronisation en temps réel des données d'un module
/// depuis Firestore vers Drift.
///
/// Écoute les changements dans les collections Firestore d'un module
/// et met à jour automatiquement la base locale.
///
/// Gère les conflits pour éviter d'écraser les modifications locales
/// non synchronisées.
class ModuleRealtimeSyncService {
  ModuleRealtimeSyncService({
    required this.firestore,
    required this.driftService,
    required this.collectionPaths,
    SyncManager? syncManager,
    ConflictResolver? conflictResolver,
  })  : _syncManager = syncManager,
        _conflictResolver = conflictResolver ?? const ConflictResolver();

  final FirebaseFirestore firestore;
  final DriftService driftService;
  final SyncManager? _syncManager;
  final ConflictResolver _conflictResolver;
  final Map<String, String Function(String p1)> collectionPaths;

  // Map pour stocker les subscriptions par module/entreprise
  final Map<String, List<StreamSubscription<QuerySnapshot>>> _subscriptions =
      {};

  bool _isListening = false;
  String? _currentEnterpriseId;
  String? _currentModuleId;

  /// Convertit les données Firestore en format JSON-compatible.
  dynamic _convertToJsonCompatible(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key as String, _convertToJsonCompatible(val)),
      );
    } else if (value is List) {
      return value.map((item) => _convertToJsonCompatible(item)).toList();
    }
    return value;
  }

  /// Sauvegarde un document dans Drift en vérifiant d'abord s'il existe déjà
  /// par remoteId pour éviter les doublons.
  ///
  /// Si un enregistrement avec le même remoteId existe, utilise son localId
  /// pour mettre à jour l'enregistrement existant au lieu d'en créer un nouveau.
  /// Gère les cas où plusieurs enregistrements ont le même remoteId (doublons).
  Future<void> _upsertWithDuplicateCheck({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    required String moduleId,
    required String dataJson,
    DateTime? localUpdatedAt,
  }) async {
    // Récupérer tous les enregistrements pour gérer les doublons
    final records = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleId,
    );
    
    // Chercher par remoteId (gérer les doublons)
    final matchingByRemote = records.where((r) => r.remoteId == documentId).toList();
    
    String localIdToUse;
    if (matchingByRemote.isNotEmpty) {
      // Si plusieurs enregistrements avec le même remoteId, prendre le plus récent
      if (matchingByRemote.length > 1) {
        matchingByRemote.sort((a, b) => 
          b.localUpdatedAt.compareTo(a.localUpdatedAt)
        );
        AppLogger.warning(
          'Multiple records found with remoteId $documentId (${matchingByRemote.length} duplicates) in $collectionName, using most recent.',
          name: 'module.realtime.sync',
        );
        // Supprimer les doublons (garder seulement le plus récent)
        for (var i = 1; i < matchingByRemote.length; i++) {
          try {
            await driftService.records.deleteByLocalId(
              collectionName: collectionName,
              localId: matchingByRemote[i].localId,
              enterpriseId: enterpriseId,
              moduleType: moduleId,
            );
          } catch (e) {
            AppLogger.warning(
              'Failed to delete duplicate record ${matchingByRemote[i].localId}: $e',
              name: 'module.realtime.sync',
              error: e,
            );
          }
        }
      }
      localIdToUse = matchingByRemote.first.localId;
    } else {
      // Aucun enregistrement trouvé, utiliser documentId comme localId
      localIdToUse = documentId;
    }

    // Sauvegarder dans Drift (mise à jour si existe, création sinon)
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localIdToUse,
      remoteId: documentId,
      enterpriseId: enterpriseId,
      moduleType: moduleId,
      dataJson: dataJson,
      localUpdatedAt: localUpdatedAt ?? DateTime.now(),
    );
  }

  /// Démarre la synchronisation en temps réel pour un module.
  ///
  /// Fait d'abord un pull initial, puis écoute les changements en temps réel.
  Future<void> startRealtimeSync({
    required String enterpriseId,
    required String moduleId,
  }) async {
    // Arrêter la sync précédente si nécessaire
    if (_isListening &&
        (_currentEnterpriseId != enterpriseId ||
            _currentModuleId != moduleId)) {
      await stopRealtimeSync();
    }

    if (_isListening &&
        _currentEnterpriseId == enterpriseId &&
        _currentModuleId == moduleId) {
      developer.log(
        'ModuleRealtimeSyncService already listening for $moduleId in enterprise $enterpriseId',
        name: 'module.realtime.sync',
      );
      return;
    }

    try {
      // 1. Pull initial : charger toutes les données depuis Firestore vers Drift
      // Seulement si on n'est pas déjà en train d'écouter (évite double pull)
      // Note: Le pull initial peut être fait plusieurs fois sans problème car
      // les données sont upsertées (pas de duplication)
      developer.log(
        'Starting initial pull for module $moduleId in enterprise $enterpriseId...',
        name: 'module.realtime.sync',
      );

      final syncService = ModuleDataSyncService(
        firestore: firestore,
        driftService: driftService,
        collectionPaths: collectionPaths,
      );
      await syncService.syncModuleData(
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      // 2. Démarrer l'écoute en temps réel pour les changements futurs
      final collectionsToSync =
          ModuleDataSyncService.moduleCollections[moduleId] ?? [];

      if (collectionsToSync.isEmpty) {
        developer.log(
          'No collections configured for module $moduleId, skipping realtime sync',
          name: 'module.realtime.sync',
        );
        return;
      }

      final subscriptionKey = '$enterpriseId/$moduleId';
      _subscriptions[subscriptionKey] = [];

      for (final collectionName in collectionsToSync) {
        // Vérifier si un chemin est configuré pour cette collection
        if (!collectionPaths.containsKey(collectionName)) {
            developer.log(
              'No path configured for collection $collectionName, skipping realtime listener',
              name: 'module.realtime.sync',
            );
            continue;
        }
        
        try {
          await _listenToCollection(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            collectionName: collectionName,
            subscriptionKey: subscriptionKey,
          );
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Error setting up realtime listener for collection $collectionName: ${appException.message}',
            name: 'module.realtime.sync',
            error: e,
            stackTrace: stackTrace,
          );
          // Continue avec les autres collections même si une échoue
        }
      }

      _isListening = true;
      _currentEnterpriseId = enterpriseId;
      _currentModuleId = moduleId;

      developer.log(
        'ModuleRealtimeSyncService started for module $moduleId in enterprise $enterpriseId',
        name: 'module.realtime.sync',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error starting realtime sync for module $moduleId: ${appException.message}',
        name: 'module.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Écoute les changements dans une collection spécifique.
  Future<void> _listenToCollection({
    required String enterpriseId,
    required String moduleId,
    required String collectionName,
    required String subscriptionKey,
  }) async {
    try {
      // Obtenir le chemin physique de la collection
      final pathBuilder = collectionPaths[collectionName];
      if (pathBuilder == null) {
        throw NotFoundException(
          'No path builder found for $collectionName',
          'PATH_BUILDER_NOT_FOUND',
        );
      }
      
      final fullPath = pathBuilder(enterpriseId);
      final collectionRef = firestore.collection(fullPath);

      final subscription = collectionRef.snapshots().listen(
        (snapshot) async {
          for (final docChange in snapshot.docChanges) {
            try {
              final data = docChange.doc.data();
              if (data == null) continue;

              final documentId = docChange.doc.id;

              // Ajouter l'ID du document dans les données
              final dataWithId = Map<String, dynamic>.from(data)
                ..['id'] = documentId;

              // Convertir les Timestamp en format JSON-compatible
              final jsonCompatibleData = _convertToJsonCompatible(dataWithId);

              // Pour les points de vente, utiliser l'enterpriseId passé en paramètre
              // (qui est l'ID de l'entreprise gaz où les points de vente sont stockés dans Firestore)
              // Les points de vente sont dans enterprises/{gaz_enterprise_id}/pointsOfSale/
              // et doivent être stockés avec cet ID dans Drift pour être récupérables
              // Note: Le parentEnterpriseId dans les données pointe vers l'entreprise mère,
              // mais le stockage dans Drift utilise l'ID de l'entreprise gaz
              String storageEnterpriseId = enterpriseId;
              if (collectionName == 'pointOfSale') {
                // Utiliser l'enterpriseId passé en paramètre (ID de l'entreprise gaz)
                // car c'est là que les points de vente sont stockés dans Firestore
                storageEnterpriseId = enterpriseId;
                final parentEnterpriseId = jsonCompatibleData['parentEnterpriseId'] as String? ??
                                           jsonCompatibleData['enterpriseId'] as String? ??
                                           'unknown';
                developer.log(
                  '🔵 SYNC (realtime): Point de vente - parentEnterpriseId=$parentEnterpriseId, stockage avec enterpriseId=$storageEnterpriseId (entreprise gaz) dans Drift',
                  name: 'module.realtime.sync',
                );
              }
              
              // Sanitizer les données avant sauvegarde locale
              final sanitizedData = DataSanitizer.sanitizeMap(jsonCompatibleData);

              switch (docChange.type) {
                case DocumentChangeType.added:
                  // Nouveau document : sauvegarder avec vérification de doublon
                  await _upsertWithDuplicateCheck(
                    collectionName: collectionName,
                    documentId: documentId,
                    enterpriseId: storageEnterpriseId,
                    moduleId: moduleId,
                    dataJson: jsonEncode(sanitizedData),
                    localUpdatedAt: DateTime.now(),
                  );
                  developer.log(
                    '${collectionName.capitalize()} added in realtime: $documentId',
                    name: 'module.realtime.sync',
                  );
                  break;
                case DocumentChangeType.modified:
                  // Document modifié : vérifier les conflits avant d'écraser
                  await _handleModifiedDocument(
                    collectionName: collectionName,
                    documentId: documentId,
                    enterpriseId: enterpriseId,
                    moduleId: moduleId,
                    firestoreData: sanitizedData,
                  );
                  break;
                case DocumentChangeType.removed:
                  // Document supprimé dans Firestore (hard delete)
                  // Vérifier s'il y a des modifications locales en attente avant de supprimer
                  bool hasPendingChanges = false;
                  final syncManager = _syncManager;
                  if (syncManager != null) {
                    final pendingOps = await syncManager.getPendingForCollection(
                      collectionName,
                    );
                    hasPendingChanges = pendingOps.any(
                      (op) => op.documentId == documentId,
                    );
                  }

                  // Si des modifications sont en attente, ne pas supprimer
                  // (les modifications locales seront synchronisées)
                  if (hasPendingChanges) {
                    developer.log(
                      '${collectionName.capitalize()} removed in Firestore but local changes pending: $documentId (skipping delete)',
                      name: 'module.realtime.sync',
                    );
                    break;
                  }

                  // Pour les points de vente, utiliser le parentEnterpriseId depuis les données
                  String deleteEnterpriseId = enterpriseId;
                  if (collectionName == 'points_of_sale') {
                    final parentEnterpriseId = jsonCompatibleData['parentEnterpriseId'] as String? ??
                                               jsonCompatibleData['enterpriseId'] as String? ??
                                               enterpriseId;
                    deleteEnterpriseId = parentEnterpriseId;
                  }
                  
                  // Supprimer localement (hard delete)
                  await driftService.records.deleteByRemoteId(
                    collectionName: collectionName,
                    remoteId: documentId,
                    enterpriseId: deleteEnterpriseId,
                    moduleType: moduleId,
                  );
                  developer.log(
                    '${collectionName.capitalize()} removed in realtime: $documentId',
                    name: 'module.realtime.sync',
                  );
                  break;
              }
            } catch (e, stackTrace) {
              final appException = ErrorHandler.instance.handleError(e, stackTrace);
              AppLogger.warning(
                'Error processing $collectionName change in realtime sync: ${appException.message}',
                name: 'module.realtime.sync',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        },
        onError: (error, stackTrace) {
          final appException = ErrorHandler.instance.handleError(error, stackTrace);
          AppLogger.error(
            'Error in $collectionName realtime stream: ${appException.message}',
            name: 'module.realtime.sync',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      _subscriptions[subscriptionKey]?.add(subscription);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up realtime listener for collection $collectionName: ${appException.message}',
        name: 'module.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Arrête la synchronisation en temps réel.
  Future<void> stopRealtimeSync() async {
    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    _subscriptions.clear();
    _isListening = false;
    _currentEnterpriseId = null;
    _currentModuleId = null;
    developer.log(
      'ModuleRealtimeSyncService stopped',
      name: 'module.realtime.sync',
    );
  }

  /// Vérifie si la synchronisation est en cours d'écoute.
  bool get isListening => _isListening;

  /// Vérifie si la synchronisation est active pour un module spécifique.
  bool isListeningTo(String enterpriseId, String moduleId) {
    return _isListening &&
        _currentEnterpriseId == enterpriseId &&
        _currentModuleId == moduleId;
  }

  /// Gère une modification de document depuis Firestore en vérifiant les conflits.
  ///
  /// Vérifie s'il y a des modifications locales en attente et compare les timestamps
  /// pour éviter d'écraser les modifications locales non synchronisées.
  Future<void> _handleModifiedDocument({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    required String moduleId,
    required Map<String, dynamic> firestoreData,
  }) async {
      // Pour les points de vente, utiliser le parentEnterpriseId depuis les données
      String storageEnterpriseId = enterpriseId;
      if (collectionName == 'pointOfSale') {
      final parentEnterpriseId = firestoreData['parentEnterpriseId'] as String? ??
                                 firestoreData['enterpriseId'] as String? ??
                                 enterpriseId;
      storageEnterpriseId = parentEnterpriseId;
      developer.log(
        'Point de vente (modified): utilisation de parentEnterpriseId=$parentEnterpriseId pour le stockage (au lieu de enterpriseId=$enterpriseId)',
        name: 'module.realtime.sync',
      );
    }
    
    try {
      // 1. Vérifier s'il y a des opérations en attente pour ce document
      bool hasPendingChanges = false;
      final syncManager = _syncManager;
      if (syncManager != null) {
        final pendingOps = await syncManager.getPendingForCollection(
          collectionName,
        );
        hasPendingChanges = pendingOps.any(
          (op) => op.documentId == documentId,
        );
      }

      // 2. Récupérer la version locale actuelle
      // Pour les points de vente, chercher avec storageEnterpriseId
      // Essayer d'abord avec storageEnterpriseId, puis avec enterpriseId si pas trouvé
      OfflineRecord? localRecord;
      if (collectionName == 'points_of_sale') {
        localRecord = await driftService.records.findByLocalId(
          collectionName: collectionName,
          localId: documentId,
          enterpriseId: storageEnterpriseId,
          moduleType: moduleId,
        );
        localRecord ??= await driftService.records.findByLocalId(
          collectionName: collectionName,
          localId: documentId,
          enterpriseId: enterpriseId,
          moduleType: moduleId,
        );
      } else {
        localRecord = await driftService.records.findByLocalId(
          collectionName: collectionName,
          localId: documentId,
          enterpriseId: enterpriseId,
          moduleType: moduleId,
        );
      }

      // Si pas trouvé par localId, essayer par remoteId (documentId = id Firestore).
      // Ex. session créée localement (local_xxx) puis synced : on a remoteId = documentId.
      // Évite de créer une 2e ligne "no local" alors qu'une existe déjà.
      localRecord ??= await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: documentId,
        enterpriseId: storageEnterpriseId,
        moduleType: moduleId,
      );
      localRecord ??= collectionName == 'points_of_sale'
          ? await driftService.records.findByRemoteId(
              collectionName: collectionName,
              remoteId: documentId,
              enterpriseId: enterpriseId,
              moduleType: moduleId,
            )
          : null;

      // 3. Si pas de version locale et pas de modifications en attente, sauvegarder directement
      if (localRecord == null && !hasPendingChanges) {
        await _upsertWithDuplicateCheck(
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: storageEnterpriseId,
          moduleId: moduleId,
          dataJson: jsonEncode(firestoreData),
          localUpdatedAt: DateTime.now(),
        );
        developer.log(
          '${collectionName.capitalize()} modified in realtime (no local): $documentId',
          name: 'module.realtime.sync',
        );
        return;
      }

      // 4. Si pas de version locale mais modifications en attente, ne pas écraser
      // (les modifications locales seront synchronisées et écraseront Firestore)
      if (localRecord == null && hasPendingChanges) {
        developer.log(
          '${collectionName.capitalize()} modified in Firestore but local changes pending: $documentId (skipping)',
          name: 'module.realtime.sync',
        );
        return;
      }

      // 5. Si version locale existe, comparer les timestamps pour résoudre le conflit
      if (localRecord != null) {
        Map<String, dynamic>? localData;
        try {
          localData = jsonDecode(localRecord.dataJson) as Map<String, dynamic>;
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Corrupted local data for $collectionName/$documentId, treating as empty/missing: ${appException.message}',
            name: 'module.realtime.sync',
            error: e,
            stackTrace: stackTrace,
          );
          // If local data is corrupted, we can't compare, so we should arguably overwrite it with server data
          // or behave as if localRecord is null. Overwriting is safer to restore consistency.
           await _upsertWithDuplicateCheck(
            collectionName: collectionName,
            documentId: documentId,
            enterpriseId: storageEnterpriseId,
            moduleId: moduleId,
            dataJson: jsonEncode(firestoreData),
            localUpdatedAt: DateTime.now(),
          );
           return;
        }
        
        final localUpdatedAt = localRecord.localUpdatedAt;

        // Extraire updatedAt de Firestore
        final firestoreUpdatedAtStr = firestoreData['updatedAt'] as String?;
        final firestoreUpdatedAt = firestoreUpdatedAtStr != null
            ? DateTime.tryParse(firestoreUpdatedAtStr)
            : null;

        // Si Firestore n'a pas de timestamp, utiliser la version locale
        if (firestoreUpdatedAt == null) {
          developer.log(
            '${collectionName.capitalize()} modified in Firestore but no updatedAt: $documentId (keeping local)',
            name: 'module.realtime.sync',
          );
          return;
        }

        // Comparer les timestamps pour déterminer quelle version est la plus récente
        final localUpdatedAtStr = localData['updatedAt'] as String?;
        final localUpdatedAtParsed = localUpdatedAtStr != null
            ? DateTime.tryParse(localUpdatedAtStr)
            : null;

        // Si la version locale n'a pas de timestamp, utiliser Firestore
        if (localUpdatedAtParsed == null) {
        await _upsertWithDuplicateCheck(
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: storageEnterpriseId,
          moduleId: moduleId,
          dataJson: jsonEncode(firestoreData),
          localUpdatedAt: DateTime.now(),
        );
        developer.log(
          '${collectionName.capitalize()} modified in realtime (local has no updatedAt): $documentId',
          name: 'module.realtime.sync',
        );
        return;
        }

        // Comparer les timestamps pour déterminer quelle version est la plus récente
        final localIsNewer = localUpdatedAtParsed.isAfter(firestoreUpdatedAt);

        // Si la version locale est plus récente et qu'il y a des modifications en attente,
        // ne pas écraser (les modifications locales seront synchronisées vers Firestore)
        if (localIsNewer && hasPendingChanges) {
          developer.log(
            '${collectionName.capitalize()} conflict: local is newer with pending changes: $documentId (skipping Firestore update)',
            name: 'module.realtime.sync',
          );
          return;
        }

        // Vérifier si Firestore contient un soft delete (deletedAt)
        final firestoreDeletedAt = firestoreData['deletedAt'];
        final localDeletedAt = localData['deletedAt'];

        // Si Firestore a un soft delete et que local n'en a pas,
        // appliquer le soft delete localement (si Firestore est plus récent ou égal)
        if (firestoreDeletedAt != null && localDeletedAt == null && !localIsNewer) {
          // Appliquer le soft delete localement
          final softDeletedData = Map<String, dynamic>.from(localData)
            ..['deletedAt'] = firestoreDeletedAt
            ..['deletedBy'] = firestoreData['deletedBy']
            ..['updatedAt'] = firestoreUpdatedAtStr;

        await _upsertWithDuplicateCheck(
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: storageEnterpriseId,
          moduleId: moduleId,
          dataJson: jsonEncode(softDeletedData),
          localUpdatedAt: DateTime.now(),
        );
          developer.log(
            '${collectionName.capitalize()} soft deleted in realtime: $documentId',
            name: 'module.realtime.sync',
          );
          return;
        }

        // Si local a un soft delete et que Firestore n'en a pas,
        // restaurer localement (si Firestore est plus récent)
        if (localDeletedAt != null && firestoreDeletedAt == null && !localIsNewer) {
          // Restaurer le document localement
          final restoredData = Map<String, dynamic>.from(firestoreData)
            ..remove('deletedAt')
            ..remove('deletedBy');

        await _upsertWithDuplicateCheck(
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: storageEnterpriseId,
          moduleId: moduleId,
          dataJson: jsonEncode(restoredData),
          localUpdatedAt: DateTime.now(),
        );
          developer.log(
            '${collectionName.capitalize()} restored in realtime: $documentId',
            name: 'module.realtime.sync',
          );
          return;
        }

        // Résoudre le conflit en utilisant ConflictResolver
        // (stratégie par défaut : lastWriteWins basé sur updatedAt)
        final resolvedData = _conflictResolver.resolve(
          localData: localData,
          serverData: firestoreData,
        );

        // Déterminer quelle version a été choisie en comparant les timestamps
        // Le ConflictResolver utilise lastWriteWins par défaut
        final choseLocal = localIsNewer;

        // Sauvegarder la version résolue
        await _upsertWithDuplicateCheck(
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: storageEnterpriseId,
          moduleId: moduleId,
          dataJson: jsonEncode(resolvedData),
          localUpdatedAt: choseLocal ? localUpdatedAt : DateTime.now(),
        );

        developer.log(
          '${collectionName.capitalize()} modified in realtime (conflict resolved): $documentId',
          name: 'module.realtime.sync',
        );
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error handling modified document $documentId: ${appException.message}',
        name: 'module.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, sauvegarder quand même pour éviter la perte de données
      try {
        // Pour les points de vente, utiliser le parentEnterpriseId depuis les données
        String fallbackEnterpriseId = enterpriseId;
        if (collectionName == 'pointOfSale') {
          final parentEnterpriseId = firestoreData['parentEnterpriseId'] as String? ??
                                     firestoreData['enterpriseId'] as String? ??
                                     enterpriseId;
          fallbackEnterpriseId = parentEnterpriseId;
        }
        
        await _upsertWithDuplicateCheck(
          collectionName: collectionName,
          documentId: documentId,
          enterpriseId: fallbackEnterpriseId,
          moduleId: moduleId,
          dataJson: jsonEncode(firestoreData),
          localUpdatedAt: DateTime.now(),
        );
      } catch (fallbackError, fallbackStackTrace) {
        final fallbackAppException = ErrorHandler.instance.handleError(fallbackError, fallbackStackTrace);
        AppLogger.error(
          'Error in fallback save: ${fallbackAppException.message}',
          name: 'module.realtime.sync',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );
      }
    }
  }
}

/// Extension pour capitaliser la première lettre d'une string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

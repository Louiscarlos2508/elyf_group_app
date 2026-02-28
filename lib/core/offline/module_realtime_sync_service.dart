import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Query;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'drift/app_database.dart';
import 'drift_service.dart';
import 'module_data_sync_service.dart';
import 'security/data_sanitizer.dart';
import 'sync_manager.dart';
import 'sync/sync_conflict_resolver.dart';

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
    SyncConflictResolver? conflictResolver,
  })  : _syncManager = syncManager,
        _conflictResolver = conflictResolver ?? SyncConflictResolver();

  final FirebaseFirestore firestore;
  final DriftService driftService;
  final SyncManager? _syncManager;
  final SyncConflictResolver _conflictResolver;
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

  Future<String> _resolveLocalId({
    required Map<String, dynamic> data,
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    required String moduleId,
  }) async {
    final embeddedLocalId = data['localId'] as String?;
    if (embeddedLocalId != null && embeddedLocalId.isNotEmpty) {
      final existingByLocalId = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: embeddedLocalId,
        enterpriseId: enterpriseId,
        moduleType: moduleId,
      );
      if (existingByLocalId != null) {
        return embeddedLocalId;
      }
    }

    final existingRecord = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: documentId,
      enterpriseId: enterpriseId,
      moduleType: moduleId,
    );
    return existingRecord?.localId ?? documentId;
  }

  Future<({Map<String, dynamic> data, DateTime updatedAt})?> _resolveConflict({
    required OfflineRecord localRecord,
    required Map<String, dynamic> firestoreData,
    required String collectionName,
  }) async {
    try {
      final localData = jsonDecode(localRecord.dataJson) as Map<String, dynamic>;
      
      // Check for pending changes
      bool hasPendingChanges = false;
      final syncManager = _syncManager;
      if (syncManager != null) {
        final pendingOps = await syncManager.getPendingForCollection(collectionName);
        hasPendingChanges = pendingOps.any((op) => op.documentId == localRecord.remoteId);
      }

      final firestoreUpdatedAtStr = firestoreData['updatedAt'] as String?;
      final firestoreUpdatedAt = firestoreUpdatedAtStr != null ? DateTime.tryParse(firestoreUpdatedAtStr) : null;
      
      if (firestoreUpdatedAt == null) return null; // Keep local

      final localUpdatedAtStr = localData['updatedAt'] as String?;
      final localUpdatedAtParsed = localUpdatedAtStr != null ? DateTime.tryParse(localUpdatedAtStr) : null;

      if (localUpdatedAtParsed == null) {
        return (data: firestoreData, updatedAt: DateTime.now());
      }

      final localIsNewer = localUpdatedAtParsed.isAfter(firestoreUpdatedAt);
      if (localIsNewer && hasPendingChanges) return null; // Keep local

      // Soft delete logic
      final firestoreDeletedAt = firestoreData['deletedAt'];
      final localDeletedAt = localData['deletedAt'];

      if (firestoreDeletedAt != null && localDeletedAt == null && !localIsNewer) {
        final softDeletedData = Map<String, dynamic>.from(localData)
          ..['deletedAt'] = firestoreDeletedAt
          ..['deletedBy'] = firestoreData['deletedBy']
          ..['updatedAt'] = firestoreUpdatedAtStr;
        return (data: softDeletedData, updatedAt: DateTime.now());
      }

      if (localDeletedAt != null && firestoreDeletedAt == null && !localIsNewer) {
        final restoredData = Map<String, dynamic>.from(firestoreData)
          ..remove('deletedAt')
          ..remove('deletedBy');
        return (data: restoredData, updatedAt: DateTime.now());
      }

      final resolvedResult = _conflictResolver.resolve(
        localData: localData,
        serverData: firestoreData,
        collectionName: collectionName,
      );

      return (
        data: resolvedResult.resolvedData,
        updatedAt: localIsNewer ? localRecord.localUpdatedAt : DateTime.now()
      );
    } catch (e) {
      AppLogger.warning('Error resolving conflict for $collectionName: $e');
      return (data: firestoreData, updatedAt: DateTime.now());
    }
  }

  /// Démarre la synchronisation en temps réel pour un module.
  ///
  /// Fait d'abord un pull initial, puis écoute les changements en temps réel.
  Future<void> startRealtimeSync({
    required String enterpriseId,
    required String moduleId,
    String? parentEnterpriseId,
  }) async {
    if (kIsWeb) {
      AppLogger.info(
        'ModuleRealtimeSyncService: Skipping sync on Web',
        name: 'module.realtime.sync',
      );
      _isListening = true;
      _currentEnterpriseId = enterpriseId;
      _currentModuleId = moduleId;
      return;
    }
    // Arrêter la sync précédente si nécessaire
    if (_isListening &&
        (_currentEnterpriseId != enterpriseId ||
            _currentModuleId != moduleId)) {
      await stopRealtimeSync();
    }

    if (_isListening &&
        _currentEnterpriseId == enterpriseId &&
        _currentModuleId == moduleId) {
      AppLogger.debug(
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
      AppLogger.info(
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
        parentEnterpriseId: parentEnterpriseId,
      );

      // 2. Démarrer l'écoute en temps réel pour les changements futurs
      final collectionsToSync =
          ModuleDataSyncService.moduleCollections[moduleId] ?? [];

      if (collectionsToSync.isEmpty) {
        AppLogger.info(
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
            AppLogger.info(
              'No path configured for collection $collectionName, skipping realtime listener',
              name: 'module.realtime.sync',
            );
            continue;
        }
        
        try {
          await _listenToCollection(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            parentEnterpriseId: parentEnterpriseId,
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

      AppLogger.info(
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
    String? parentEnterpriseId,
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
      
      // Déterminer l'ID de l'entreprise à utiliser pour le chemin Firestore
      final isShared = ModuleDataSyncService.sharedCollections[moduleId]?.contains(collectionName) ?? false;
      final effectivePathEnterpriseId = (isShared && parentEnterpriseId != null) 
          ? parentEnterpriseId 
          : enterpriseId;

      final fullPath = pathBuilder(effectivePathEnterpriseId);
      final collectionRef = firestore.collection(fullPath);

      final subscription = collectionRef.snapshots().listen(
        (snapshot) async {
          if (snapshot.docChanges.isEmpty) return;

          final itemsToUpsert = <OfflineRecordsCompanion>[];
          final itemsToRemove = <String>[]; // List of remoteIds to remove

          for (final docChange in snapshot.docChanges) {
            try {
              final data = docChange.doc.data();
              if (data == null) continue;

              final documentId = docChange.doc.id;
              final dataWithId = Map<String, dynamic>.from(data)..['id'] = documentId;
              final jsonCompatibleData = _convertToJsonCompatible(dataWithId);
              final sanitizedData = DataSanitizer.sanitizeMap(jsonCompatibleData);
              final jsonPayload = jsonEncode(sanitizedData);

              String storageEnterpriseId = isShared ? effectivePathEnterpriseId : enterpriseId;

              if (collectionName == 'pointOfSale') {
                storageEnterpriseId = (sanitizedData['parentEnterpriseId'] as String?) ??
                                     (sanitizedData['enterpriseId'] as String?) ??
                                     storageEnterpriseId;
              }

              switch (docChange.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  // For realtime sync, we still need to check conflicts but we can collect them
                  // However, conflict resolution involves async lookups, so we'll do it sequentially
                  // BUT we wrap it in a single batch at the end for the upserts.
                  
                  // Optimisation: if it's "added", we rarely have local record unless it was just created 
                  // and we are getting the server echo.
                  
                  final localId = await _resolveLocalId(
                    data: sanitizedData,
                    collectionName: collectionName,
                    documentId: documentId,
                    enterpriseId: storageEnterpriseId,
                    moduleId: moduleId,
                  );

                  // Conflict check for modified
                  if (docChange.type == DocumentChangeType.modified) {
                    final localRecord = await driftService.records.findByLocalId(
                      collectionName: collectionName,
                      localId: localId,
                      enterpriseId: storageEnterpriseId,
                      moduleType: moduleId,
                    );
                    
                    if (localRecord != null) {
                       final resolvedData = await _resolveConflict(
                         localRecord: localRecord,
                         firestoreData: sanitizedData,
                         collectionName: collectionName,
                       );
                       if (resolvedData != null) {
                         itemsToUpsert.add(OfflineRecordsCompanion.insert(
                            collectionName: collectionName,
                            localId: localId,
                            remoteId: Value(documentId),
                            enterpriseId: storageEnterpriseId,
                            moduleType: Value(moduleId),
                            dataJson: jsonEncode(resolvedData.data),
                            localUpdatedAt: resolvedData.updatedAt,
                          ));
                       }
                       continue;
                    }
                  }

                  itemsToUpsert.add(OfflineRecordsCompanion.insert(
                    collectionName: collectionName,
                    localId: localId,
                    remoteId: Value(documentId),
                    enterpriseId: storageEnterpriseId,
                    moduleType: Value(moduleId),
                    dataJson: jsonPayload,
                    localUpdatedAt: DateTime.now(),
                  ));
                  break;

                case DocumentChangeType.removed:
                  itemsToRemove.add(documentId);
                  break;
              }
            } catch (e) {
               AppLogger.warning('Error processing doc change: $e');
            }
          }

          // Apply Batch
          if (itemsToUpsert.isNotEmpty) {
            await driftService.records.upsertAll(itemsToUpsert);
          }
          
          for (final remoteId in itemsToRemove) {
            await driftService.records.deleteByRemoteId(
              collectionName: collectionName,
              remoteId: remoteId,
              enterpriseId: enterpriseId,
              moduleType: moduleId,
            );
          }
        },
        onError: (error, stackTrace) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            developer.log(
              'Permission denied for realtime stream on $collectionName for enterprise $enterpriseId. Ignoring.',
              name: 'module.realtime.sync',
            );
            return;
          }
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
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        developer.log(
          'Permission denied setting up realtime listener for $collectionName in enterprise $enterpriseId. Ignoring.',
          name: 'module.realtime.sync',
        );
      } else {
        rethrow;
      }
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
    AppLogger.info(
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
}

/// Extension pour capitaliser la première lettre d'une string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

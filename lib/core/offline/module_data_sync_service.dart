import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Query;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'collection_names.dart';
import 'drift_service.dart';
import 'drift/app_database.dart';
import 'security/data_sanitizer.dart';
import 'sync_manager.dart';
import 'sync/sync_conflict_resolver.dart';

/// Service pour synchroniser les données d'un module depuis Firestore vers Drift.
///
/// Ce service permet de synchroniser automatiquement les collections d'un module
/// lors de l'accès au module.
class ModuleDataSyncService {
  ModuleDataSyncService({
    required this.firestore,
    required this.driftService,
    required this.collectionPaths,
    SyncManager? syncManager,
    SyncConflictResolver? conflictResolver,
  })  : _syncManager = syncManager,
        _conflictResolver = conflictResolver ?? const SyncConflictResolver();

  final FirebaseFirestore firestore;
  final DriftService driftService;
  final SyncManager? _syncManager;
  final SyncConflictResolver _conflictResolver;
  final Map<String, String Function(String p1)> collectionPaths;

  /// Configuration des collections partagées (qui doivent être sync depuis le parent si dispo).
  static const Map<String, List<String>> sharedCollections = {
    'orange_money': [
      'agences',
      'orange_money_settings',
    ],
  };

  /// Configuration des collections par module.
  ///
  /// Définit quelles collections doivent être synchronisées pour chaque module.
  static const Map<String, List<String>> moduleCollections = {
    'boutique': [
      'products',
      'sales',
      'purchases',
      'expenses',
      'suppliers',
      'supplier_settlements',
      'treasury_operations',
      'closings',
    ],
    'eau_minerale': [
      CollectionNames.products,
      CollectionNames.sales,
      CollectionNames.customers,
      CollectionNames.machines,
      CollectionNames.bobineStocks,
      CollectionNames.productionSessions,
      CollectionNames.stockMovements,
      CollectionNames.stockItems,
      CollectionNames.employees,
      CollectionNames.salaryPayments,
      CollectionNames.productionPayments,
      CollectionNames.creditPayments,
      CollectionNames.dailyWorkers,
      CollectionNames.expenseRecords,
      CollectionNames.packagingStocks,
      CollectionNames.bobineStockMovements,
      CollectionNames.packagingStockMovements,
      CollectionNames.eauMineraleTreasuryOperations,
      CollectionNames.suppliers,
      CollectionNames.supplierSettlements,
      CollectionNames.purchases,
      CollectionNames.closings,
    ],
    'gaz': [
      'cylinders',
      'gas_sales',
      'cylinder_stocks',
      'cylinder_leaks',
      'gaz_expenses',
      'tours',
      'pointOfSale',
      'gaz_settings',
      'financial_reports',
      'stock_transfers',
      'gas_collections',
      'gaz_sessions',
      'gaz_treasury_operations',
      'wholesalers',
      'inventory_audits',
      CollectionNames.gazPosRemittances,
      CollectionNames.gazSiteLogisticsRecords,
    ],
    'orange_money': [
      'transactions',
      'agents',
      'commissions',
      'liquidity_checkpoints',
      'orange_money_settings',
      'agences',
    ],
    'immobilier': [
      'properties',
      'tenants',
      'contracts',
      'payments',
      'property_expenses',
    ],
  };

  /// Configuration des collections essentielles (pour sync rapide/mobile).
  static const Map<String, List<String>> essentialCollections = {
    'boutique': [
      'products',
      'sales',
      'treasury_operations',
    ],
    'eau_minerale': [
      CollectionNames.products,
      CollectionNames.sales,
      CollectionNames.stockItems,
      CollectionNames.eauMineraleTreasuryOperations,
      CollectionNames.productionSessions,
      CollectionNames.suppliers,
    ],
    'gaz': [
      'gas_sales',
      'cylinder_stocks',
      'pointOfSale',
      'gaz_treasury_operations',
    ],
    'orange_money': [
      'transactions',
      'orange_money_settings',
    ],
    'immobilier': [
      'tenants',
      'contracts',
      'payments',
    ],
  };

  /// Synchronise les collections d'un module depuis Firestore vers Drift.
  ///
  /// [enterpriseId] : ID de l'entreprise
  /// [moduleId] : ID du module (ex: 'boutique', 'gaz', etc.)
  /// [collections] : Liste optionnelle des collections à synchroniser.
  ///                 Si non fournie, utilise la configuration par défaut du module.
  /// [lastSyncAt] : Timestamp de la dernière sync (pour delta sync).
  ///                Si null, fait un pull complet.
  Future<void> syncModuleData({
    required String enterpriseId,
    required String moduleId,
    String? parentEnterpriseId,
    List<String>? collections,
    DateTime? lastSyncAt,
    bool essentialOnly = false,
  }) async {
    if (kIsWeb) return;
    
    // Utiliser la configuration par défaut si collections n'est pas fourni
    var collectionsToSync = collections ?? moduleCollections[moduleId] ?? [];

    if (essentialOnly) {
      final essentials = essentialCollections[moduleId] ?? [];
      // Intersection entre les collections prévues et les collections essentielles
      collectionsToSync = collectionsToSync.where(essentials.contains).toList();
      
      if (collectionsToSync.isEmpty && essentials.isNotEmpty) {
        // Si l'intersection est vide mais qu'il y a des essentiels définis,
        // on prend les essentiels par défaut du module.
        collectionsToSync = essentials;
      }
    }

    if (collectionsToSync.isEmpty) {
      AppLogger.info(
        'No collections to sync for module $moduleId (essentialOnly: $essentialOnly), skipping',
        name: 'module.sync',
      );
      return;
    }
    try {
      AppLogger.info(
        'Starting sync for module $moduleId in enterprise $enterpriseId',
        name: 'module.sync',
      );

      for (final collectionName in collectionsToSync) {
        try {
          // Vérifier si un chemin est configuré pour cette collection
          if (!collectionPaths.containsKey(collectionName)) {
            AppLogger.info(
              'No path configured for collection $collectionName, skipping sync',
              name: 'module.sync',
            );
            continue;
          }

          await _syncCollection(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            parentEnterpriseId: parentEnterpriseId,
            collectionName: collectionName,
            lastSyncAt: lastSyncAt,
          );
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Error syncing collection $collectionName: ${appException.message}',
            name: 'module.sync',
            error: e,
            stackTrace: stackTrace,
          );
          // Continue avec les autres collections même si une échoue
        }
      }

      AppLogger.info(
        'Sync completed for module $moduleId in enterprise $enterpriseId',
        name: 'module.sync',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error during module data sync: ${appException.message}',
        name: 'module.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Convertit les données Firestore en format JSON-compatible.
  ///
  /// Convertit les objets Timestamp en String ISO 8601.
  dynamic _convertToJsonCompatible(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key as String, _convertToJsonCompatible(val)),
      );
    } else if (value is List) {
      return value.map(_convertToJsonCompatible).toList();
    }
    return value;
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
        // Robust ID matching: check BOTH localId and remoteId
        // This is critical because a pending 'create' uses localId, 
        // while 'update' after sync might use remoteId, but both belong to our entity.
        hasPendingChanges = pendingOps.any((op) => 
          op.documentId == localRecord.localId || 
          (localRecord.remoteId != null && op.documentId == localRecord.remoteId)
        );
      }

      final firestoreUpdatedAtStr = firestoreData['updatedAt'] as String?;
      final firestoreUpdatedAt = firestoreUpdatedAtStr != null ? DateTime.tryParse(firestoreUpdatedAtStr) : null;
      
      if (firestoreUpdatedAt == null) return null; // Keep local if server has no timestamp

      final localUpdatedAtStr = localData['updatedAt'] as String?;
      final localUpdatedAtParsed = localUpdatedAtStr != null ? DateTime.tryParse(localUpdatedAtStr) : null;

      // CRITICAL: If has pending changes, we MUST keep local, regardless of timestamp.
      // The pending change in queue is the absolute truth of user intent.
      if (hasPendingChanges) {
        AppLogger.debug(
          'Keeping local version for $collectionName/${localRecord.localId} due to pending changes in queue',
          name: 'module.sync',
        );
        return null; 
      }

      if (localUpdatedAtParsed == null) {
        return (data: firestoreData, updatedAt: DateTime.now());
      }

      final localIsNewer = localUpdatedAtParsed.isAfter(firestoreUpdatedAt);

      // Soft delete logic (inherited from RealtimeSyncService for consistency)
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

      // If resolver chose local data and we have pending changes, return null (skip update)
      if (resolvedResult.resolvedData == localData && hasPendingChanges) {
        return null;
      }

      return (
        data: resolvedResult.resolvedData,
        updatedAt: localIsNewer ? localRecord.localUpdatedAt : DateTime.now()
      );
    } catch (e) {
      AppLogger.warning('Error resolving conflict for $collectionName: $e');
      return (data: firestoreData, updatedAt: DateTime.now());
    }
  }

  /// Synchronise une collection depuis Firestore vers Drift.
  ///
  /// Utilise delta sync (sync incrémentale) si lastSyncAt est fourni,
  /// sinon fait un pull complet.
  Future<void> _syncCollection({
    required String enterpriseId,
    required String moduleId,
    String? parentEnterpriseId,
    required String collectionName,
    DateTime? lastSyncAt,
  }) async {
    if (kIsWeb) return;

    try {
      // Obtenir le chemin physique de la collection
      // La fonction retourne le path complet (ex: enterprises/123/gasSales)
      final pathBuilder = collectionPaths[collectionName];
      if (pathBuilder == null) {
        throw NotFoundException(
          'No path builder found for $collectionName',
          'PATH_BUILDER_NOT_FOUND',
        );
      }
      
      // Déterminer l'ID de l'entreprise à utiliser pour le chemin Firestore
      final isShared = sharedCollections[moduleId]?.contains(collectionName) ?? false;
      
      if (isShared && parentEnterpriseId == null) {
        AppLogger.warning(
          'SYNC WARNING: Collection $collectionName is shared but parentEnterpriseId is null for enterprise $enterpriseId. Skipping sync to avoid permission errors.',
          name: 'module.sync',
        );
        return;
      }

      final effectivePathEnterpriseId = isShared ? parentEnterpriseId! : enterpriseId;

      final fullPath = pathBuilder(effectivePathEnterpriseId);
      final collectionRef = firestore.collection(fullPath);

      Query query = collectionRef;
      
      // Delta sync: récupérer uniquement les documents modifiés depuis lastSyncAt
      if (lastSyncAt != null) {
        query = collectionRef.where(
          'updatedAt',
          isGreaterThan: Timestamp.fromDate(lastSyncAt),
        );
        AppLogger.debug(
          'Delta sync for $collectionName since ${lastSyncAt.toIso8601String()}',
          name: 'module.sync',
        );
      }

      // Récupérer les documents (tous ou seulement modifiés)
      final snapshot = await query.get();

      AppLogger.debug(
        'SYNC: Syncing $collectionName for enterprise $enterpriseId: ${snapshot.docs.length} documents found in Firestore',
        name: 'module.sync',
      );

      if (snapshot.docs.isEmpty) return;

      final companions = <OfflineRecordsCompanion>[];

      // Sauvegarder chaque document dans Drift
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final documentId = doc.id;
          
          final dataWithId = Map<String, dynamic>.from(data)
            ..['id'] = documentId;

          final jsonCompatibleData = _convertToJsonCompatible(dataWithId);
          final sanitizedData = DataSanitizer.sanitizeMap(jsonCompatibleData);
          
          String storageEnterpriseId = isShared ? effectivePathEnterpriseId : enterpriseId;
          
          if (collectionName == 'pointOfSale') {
            storageEnterpriseId = (sanitizedData['parentEnterpriseId'] as String?) ?? 
                                 (sanitizedData['enterpriseId'] as String?) ?? 
                                 storageEnterpriseId;
          }
          
          final embeddedLocalId = sanitizedData['localId'] as String?;
          OfflineRecord? existingRecord;

          if (embeddedLocalId != null && embeddedLocalId.isNotEmpty) {
            existingRecord = await driftService.records.findByLocalIdAny(
              collectionName: collectionName,
              localId: embeddedLocalId,
              enterpriseId: storageEnterpriseId,
            );
          }

          existingRecord ??= await driftService.records.findByRemoteIdAny(
              collectionName: collectionName,
              remoteId: documentId,
              enterpriseId: storageEnterpriseId,
            );

          if (existingRecord != null && existingRecord.moduleType != moduleId) {
            await driftService.records.deleteById(existingRecord.id);
            existingRecord = null;
          }

          final localIdToUse = existingRecord?.localId ?? embeddedLocalId ?? documentId;
          final finalLocalId = localIdToUse.trim().isEmpty ? documentId : localIdToUse;

          Map<String, dynamic> finalData = sanitizedData;
          DateTime finalUpdatedAt = DateTime.now();

          // Conflict resolution logic
          if (existingRecord != null) {
            final resolution = await _resolveConflict(
              localRecord: existingRecord,
              firestoreData: sanitizedData,
              collectionName: collectionName,
            );

            if (resolution == null) {
              // Resolution null means "skip update, keep local"
              AppLogger.debug(
                'Skipping update for $collectionName/$finalLocalId to protect local changes',
                name: 'module.sync',
              );
              continue;
            }

            finalData = resolution.data;
            finalUpdatedAt = resolution.updatedAt;
          }

          finalData['localId'] = finalLocalId;
          finalData['enterpriseId'] = storageEnterpriseId;
          final jsonPayload = jsonEncode(finalData);
          
          try {
            DataSanitizer.validateJsonSize(jsonPayload);
          } on DataSizeException catch (e) {
            AppLogger.warning(
              'Document ${doc.id} in collection $collectionName exceeds size limit: ${e.message}. Skipping.',
              name: 'module.sync',
              error: e,
            );
            continue;
          }

          companions.add(OfflineRecordsCompanion.insert(
            collectionName: collectionName,
            localId: finalLocalId,
            remoteId: Value(documentId),
            enterpriseId: storageEnterpriseId,
            moduleType: Value(moduleId),
            dataJson: jsonPayload,
            localUpdatedAt: finalUpdatedAt,
          ));
        } catch (e) {
          AppLogger.warning(
            'SYNC ERROR: Error parsing document ${doc.id} in collection $collectionName for enterprise $enterpriseId: $e',
            name: 'module.sync',
          );
        }
      }

      if (companions.isNotEmpty) {
        await driftService.records.upsertAll(companions);
      }

      AppLogger.info(
        'Completed syncing $collectionName: ${snapshot.docs.length} documents (Batched)',
        name: 'module.sync',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
         AppLogger.warning(
          'SYNC PERMISSION: Permission denied reading collection $collectionName for enterprise $enterpriseId. Ignoring.',
          name: 'module.sync',
        );
      } else {
         rethrow;
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error syncing collection $collectionName: ${appException.message}',
        name: 'module.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

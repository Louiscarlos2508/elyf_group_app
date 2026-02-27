import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Query;

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'collection_names.dart';
import 'drift_service.dart';
import 'drift/app_database.dart';
import 'security/data_sanitizer.dart';

/// Service pour synchroniser les données d'un module depuis Firestore vers Drift.
///
/// Ce service permet de synchroniser automatiquement les collections d'un module
/// lors de l'accès au module.
class ModuleDataSyncService {
  ModuleDataSyncService({
    required this.firestore,
    required this.driftService,
    required this.collectionPaths,
  });

  final FirebaseFirestore firestore;
  final DriftService driftService;
  final Map<String, String Function(String p1)> collectionPaths;

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
    ],
    'orange_money': [
      'transactions',
      'agents',
      'commissions',
      'liquidity_checkpoints',
      'orange_money_settings',
    ],
    'immobilier': [
      'properties',
      'tenants',
      'contracts',
      'payments',
      'property_expenses', // Correction: was 'expenses' which is ambiguous, verify bootstrap match
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
    List<String>? collections,
    DateTime? lastSyncAt,
  }) async {
    // Utiliser la configuration par défaut si collections n'est pas fourni
    final collectionsToSync = collections ?? moduleCollections[moduleId] ?? [];

    if (collectionsToSync.isEmpty) {
      AppLogger.info(
        'No collections configured for module $moduleId, skipping sync',
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
      return value.map((item) => _convertToJsonCompatible(item)).toList();
    }
    return value;
  }

  /// Synchronise une collection depuis Firestore vers Drift.
  ///
  /// Utilise delta sync (sync incrémentale) si lastSyncAt est fourni,
  /// sinon fait un pull complet.
  Future<void> _syncCollection({
    required String enterpriseId,
    required String moduleId,
    required String collectionName,
    DateTime? lastSyncAt,
  }) async {
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
      
      final fullPath = pathBuilder(enterpriseId);
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

          // Ajouter l'ID du document dans les données
          final dataWithId = Map<String, dynamic>.from(data)
            ..['id'] = documentId;

          // Convertir les Timestamp en format JSON-compatible
          final jsonCompatibleData = _convertToJsonCompatible(dataWithId);

          // Sanitizer et valider les données avant sauvegarde locale
          final sanitizedData = DataSanitizer.sanitizeMap(jsonCompatibleData);
          final jsonPayload = jsonEncode(sanitizedData);
          
          // Valider la taille du payload
          try {
            DataSanitizer.validateJsonSize(jsonPayload);
          } on DataSizeException catch (e) {
            AppLogger.warning(
              'Document ${doc.id} in collection $collectionName exceeds size limit: ${e.message}. Skipping.',
              name: 'module.sync',
              error: e,
            );
            continue; // Skip ce document et continuer avec les autres
          }

          String storageEnterpriseId = enterpriseId;
          // Note: specific logic for pointOfSale remains as is but integrated into batch
          
          // Vérifier si un enregistrement avec le même localId embarqué existe d'abord
          // Utiliser les finders Any (sans filtre moduleType) pour trouver même les
          // anciens enregistrements sauvés avec moduleType vide.
          final embeddedLocalId = sanitizedData['localId'] as String?;
          OfflineRecord? existingRecord;

          if (embeddedLocalId != null && embeddedLocalId.isNotEmpty) {
            existingRecord = await driftService.records.findByLocalIdAny(
              collectionName: collectionName,
              localId: embeddedLocalId,
              enterpriseId: storageEnterpriseId,
            );
          }

          // Si pas trouvé par localId embarqué, chercher par remoteId (sans filtre moduleType)
          existingRecord ??= await driftService.records.findByRemoteIdAny(
              collectionName: collectionName,
              remoteId: documentId,
              enterpriseId: storageEnterpriseId,
            );

          // Si l'existingRecord a un moduleType différent (ex: ''), le supprimer d'abord
          // pour éviter la violation de contrainte UNIQUE lors de l'upsert.
          if (existingRecord != null && existingRecord.moduleType != moduleId) {
            await driftService.records.deleteById(existingRecord.id);
            existingRecord = null; // Sera recréé avec le bon moduleType
          }

          // Utiliser le localId existant si trouvé, sinon le localId embarqué, sinon utiliser documentId
          final localIdToUse = existingRecord?.localId ?? embeddedLocalId ?? documentId;

          // Si on utilise embeddedLocalId, valider qu'il n'est pas vide
          final finalLocalId = localIdToUse.trim().isEmpty ? documentId : localIdToUse;

          // Crucial : Injecter le finalLocalId déterminé dans les données stockées
          // Pour que les fromMap() puissent toujours retrouver leur localId.
          sanitizedData['localId'] = finalLocalId;
          final updatedJsonPayload = jsonEncode(sanitizedData);

          companions.add(OfflineRecordsCompanion.insert(
            collectionName: collectionName,
            localId: finalLocalId,
            remoteId: Value(documentId),
            enterpriseId: storageEnterpriseId,
            moduleType: Value(moduleId),
            dataJson: updatedJsonPayload,
            localUpdatedAt: DateTime.now(),
          ));
        } catch (e) {
          AppLogger.warning(
            'Error preparing document ${doc.id} for sync: $e',
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

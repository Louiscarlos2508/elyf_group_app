import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';
import 'collection_names.dart';
import 'drift_service.dart';
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
    'boutique': ['products', 'sales', 'purchases', 'expenses'],
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
      developer.log(
        'No collections configured for module $moduleId, skipping sync',
        name: 'module.sync',
      );
      return;
    }
    try {
      developer.log(
        'Starting sync for module $moduleId in enterprise $enterpriseId',
        name: 'module.sync',
      );

      for (final collectionName in collectionsToSync) {
        try {
          // Vérifier si un chemin est configuré pour cette collection
          if (!collectionPaths.containsKey(collectionName)) {
            developer.log(
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

      developer.log(
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
        developer.log(
          'Delta sync for $collectionName since ${lastSyncAt.toIso8601String()}',
          name: 'module.sync',
        );
      }

      // Récupérer les documents (tous ou seulement modifiés)
      final snapshot = await query.get();

      developer.log(
        '🔵 SYNC: Syncing $collectionName for enterprise $enterpriseId: ${snapshot.docs.length} documents found in Firestore',
        name: 'module.sync',
      );

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
            final posName = sanitizedData['name'] as String? ?? 'unknown';
            final parentEnterpriseId = sanitizedData['parentEnterpriseId'] as String? ??
                                       sanitizedData['enterpriseId'] as String? ??
                                       'unknown';
            developer.log(
              '🔵 SYNC: Point de vente "$posName" (id: $documentId) - parentEnterpriseId=$parentEnterpriseId, stockage avec enterpriseId=$storageEnterpriseId (entreprise gaz) dans Drift',
              name: 'module.sync',
            );
          }
          
          // Vérifier si un enregistrement avec le même remoteId existe déjà
          // pour éviter les doublons lors de la synchronisation
          final existingRecord = await driftService.records.findByRemoteId(
            collectionName: collectionName,
            remoteId: documentId,
            enterpriseId: storageEnterpriseId,
            moduleType: moduleId,
          );

          // Utiliser le localId existant si trouvé, sinon utiliser documentId
          final localIdToUse = existingRecord?.localId ?? documentId;

          // Sauvegarder dans Drift (mise à jour si existe, création sinon)
          await driftService.records.upsert(
            collectionName: collectionName,
            localId: localIdToUse,
            remoteId: documentId,
            enterpriseId: storageEnterpriseId,
            moduleType: moduleId,
            dataJson: jsonPayload,
            localUpdatedAt: DateTime.now(),
          );
          
          if (collectionName == 'pointOfSale') {
            developer.log(
              '🔵 SYNC: Point de vente sauvegardé dans Drift avec enterpriseId=$storageEnterpriseId, moduleType=$moduleId',
              name: 'module.sync',
            );
          }
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          AppLogger.warning(
            'Error syncing document ${doc.id} in collection $collectionName: ${appException.message}',
            name: 'module.sync',
            error: e,
            stackTrace: stackTrace,
          );
          // Continue avec les autres documents même si un échoue
        }
      }

      developer.log(
        'Completed syncing $collectionName: ${snapshot.docs.length} documents',
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

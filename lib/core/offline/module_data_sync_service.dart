import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

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
      'products',
      'sales',
      'customers',
      'machines',
      'bobine_stocks',
      'production_sessions',
      'stock_movements',
      'stock_items',
      'employees',
      'salary_payments',
      'production_payments',
      'credit_payments',
      'daily_workers',
      'expense_records',
      'packaging_stocks',
      'bobine_stock_movements',
      'packaging_stock_movements',
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
          developer.log(
            'Error syncing collection $collectionName: $e',
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
      developer.log(
        'Error during module data sync: $e',
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
        throw Exception('No path builder found for $collectionName');
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
        'Syncing $collectionName: ${snapshot.docs.length} documents',
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
            developer.log(
              'Document ${doc.id} in collection $collectionName exceeds size limit: ${e.message}. Skipping.',
              name: 'module.sync',
            );
            continue; // Skip ce document et continuer avec les autres
          }

          // Pour les points de vente, utiliser le parentEnterpriseId depuis les données
          // au lieu de l'enterpriseId passé en paramètre
          // Car les points de vente sont dans enterprises/{parentEnterpriseId}/pointofsale/
          String storageEnterpriseId = enterpriseId;
          if (collectionName == 'pointOfSale') {
            final parentEnterpriseId = sanitizedData['parentEnterpriseId'] as String? ??
                                       sanitizedData['enterpriseId'] as String? ??
                                       enterpriseId;
            storageEnterpriseId = parentEnterpriseId;
            developer.log(
              'Point de vente: utilisation de parentEnterpriseId=$parentEnterpriseId pour le stockage (au lieu de enterpriseId=$enterpriseId)',
              name: 'module.sync',
            );
          }
          
          // Sauvegarder dans Drift
          await driftService.records.upsert(
            collectionName: collectionName,
            localId: documentId,
            remoteId: documentId,
            enterpriseId: storageEnterpriseId,
            moduleType: moduleId,
            dataJson: jsonPayload,
            localUpdatedAt: DateTime.now(),
          );
        } catch (e, stackTrace) {
          developer.log(
            'Error syncing document ${doc.id} in collection $collectionName: $e',
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
      developer.log(
        'Error syncing collection $collectionName: $e',
        name: 'module.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

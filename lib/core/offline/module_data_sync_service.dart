import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'drift_service.dart';

/// Service pour synchroniser les données d'un module depuis Firestore vers Drift.
///
/// Ce service permet de synchroniser automatiquement les collections d'un module
/// lors de l'accès au module.
class ModuleDataSyncService {
  ModuleDataSyncService({required this.firestore, required this.driftService});

  final FirebaseFirestore firestore;
  final DriftService driftService;

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
    ],
    'gaz': [
      'cylinders',
      'gas_sales',
      'cylinder_stocks',
      'cylinder_leaks',
      'gaz_expenses',
      'tours',
      'points_of_sale',
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
      'expenses',
    ],
  };

  /// Synchronise les collections d'un module depuis Firestore vers Drift.
  ///
  /// [enterpriseId] : ID de l'entreprise
  /// [moduleId] : ID du module (ex: 'boutique', 'gaz', etc.)
  /// [collections] : Liste optionnelle des collections à synchroniser.
  ///                 Si non fournie, utilise la configuration par défaut du module.
  Future<void> syncModuleData({
    required String enterpriseId,
    required String moduleId,
    List<String>? collections,
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
          await _syncCollection(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            collectionName: collectionName,
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
  Future<void> _syncCollection({
    required String enterpriseId,
    required String moduleId,
    required String collectionName,
  }) async {
    try {
      // Construire la référence de collection Firestore
      // Structure simplifiée: enterprises/{enterpriseId}/{collectionName}
      // (compatible avec la structure utilisée dans bootstrap.dart)
      final collectionRef = firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection(collectionName);

      // Récupérer tous les documents
      final snapshot = await collectionRef.get();

      developer.log(
        'Syncing $collectionName: ${snapshot.docs.length} documents',
        name: 'module.sync',
      );

      // Sauvegarder chaque document dans Drift
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final documentId = doc.id;

          // Ajouter l'ID du document dans les données
          final dataWithId = Map<String, dynamic>.from(data)
            ..['id'] = documentId;

          // Convertir les Timestamp en format JSON-compatible
          final jsonCompatibleData = _convertToJsonCompatible(dataWithId);

          // Sauvegarder dans Drift
          await driftService.records.upsert(
            collectionName: collectionName,
            localId: documentId,
            remoteId: documentId,
            enterpriseId: enterpriseId,
            moduleType: moduleId,
            dataJson: jsonEncode(jsonCompatibleData),
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

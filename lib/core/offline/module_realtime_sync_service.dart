import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'drift_service.dart';
import 'module_data_sync_service.dart';

/// Service pour la synchronisation en temps réel des données d'un module
/// depuis Firestore vers Drift.
///
/// Écoute les changements dans les collections Firestore d'un module
/// et met à jour automatiquement la base locale.
class ModuleRealtimeSyncService {
  ModuleRealtimeSyncService({
    required this.firestore,
    required this.driftService,
  });

  final FirebaseFirestore firestore;
  final DriftService driftService;

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
      developer.log(
        'Starting initial pull for module $moduleId in enterprise $enterpriseId...',
        name: 'module.realtime.sync',
      );

      final syncService = ModuleDataSyncService(
        firestore: firestore,
        driftService: driftService,
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
        try {
          await _listenToCollection(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            collectionName: collectionName,
            subscriptionKey: subscriptionKey,
          );
        } catch (e, stackTrace) {
          developer.log(
            'Error setting up realtime listener for collection $collectionName: $e',
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
      developer.log(
        'Error starting realtime sync for module $moduleId',
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
      // Construire la référence de collection Firestore
      // Structure: enterprises/{enterpriseId}/{collectionName}
      final collectionRef = firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection(collectionName);

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

              switch (docChange.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  // Sauvegarder localement dans Drift
                  await driftService.records.upsert(
                    collectionName: collectionName,
                    localId: documentId,
                    remoteId: documentId,
                    enterpriseId: enterpriseId,
                    moduleType: moduleId,
                    dataJson: jsonEncode(jsonCompatibleData),
                    localUpdatedAt: DateTime.now(),
                  );
                  developer.log(
                    '${collectionName.capitalize()} ${docChange.type.name} in realtime: $documentId',
                    name: 'module.realtime.sync',
                  );
                  break;
                case DocumentChangeType.removed:
                  // Supprimer localement
                  await driftService.records.deleteByRemoteId(
                    collectionName: collectionName,
                    remoteId: documentId,
                    enterpriseId: enterpriseId,
                    moduleType: moduleId,
                  );
                  developer.log(
                    '${collectionName.capitalize()} removed in realtime: $documentId',
                    name: 'module.realtime.sync',
                  );
                  break;
              }
            } catch (e, stackTrace) {
              developer.log(
                'Error processing ${collectionName} change in realtime sync: $e',
                name: 'module.realtime.sync',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        },
        onError: (error) {
          developer.log(
            'Error in $collectionName realtime stream: $error',
            name: 'module.realtime.sync',
            error: error,
          );
        },
      );

      _subscriptions[subscriptionKey]?.add(subscription);
    } catch (e, stackTrace) {
      developer.log(
        'Error setting up realtime listener for collection $collectionName',
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
}

/// Extension pour capitaliser la première lettre d'une string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

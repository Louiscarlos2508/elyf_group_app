import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../drift_service.dart';
import '../sync_manager.dart';
import '../sync_status.dart';
import '../security/data_sanitizer.dart';

/// Firebase Firestore implementation of [SyncOperationHandler].
///
/// Handles synchronization of local operations to Firebase Firestore.
///
/// Vérifie les conflits avant d'écraser Firestore avec des données locales
/// pour éviter de perdre des modifications Firestore plus récentes.
class FirebaseSyncHandler implements SyncOperationHandler {
  FirebaseSyncHandler({
    required this.firestore,
    required this.collectionPaths,
    this.conflictResolver = const ConflictResolver(),
    DriftService? driftService,
  }) : _driftService = driftService;

  final FirebaseFirestore firestore;
  final Map<String, String Function(String? enterpriseId)> collectionPaths;
  final ConflictResolver conflictResolver;
  final DriftService? _driftService;

  @override
  Future<void> processOperation(SyncOperation operation) async {
    final pathBuilder = collectionPaths[operation.collectionName];
    if (pathBuilder == null) {
      throw SyncException(
        'No path configured for collection: ${operation.collectionName}',
      );
    }

    final collectionPath = pathBuilder(operation.enterpriseId);
    final collection = firestore.collection(collectionPath);

    switch (operation.operationType) {
      case 'create':
        await _handleCreate(collection, operation);
      case 'update':
        await _handleUpdate(collection, operation);
      case 'delete':
        await _handleDelete(collection, operation);
      default:
        throw SyncException(
          'Unknown operation type: ${operation.operationType}',
        );
    }
  }

  Future<void> _handleCreate(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    // Sanitizer les données avant de les envoyer à Firestore
    final rawData = operation.payloadMap ?? {};
    final sanitizedData = DataSanitizer.sanitizeMap(rawData);
    
    // Ajouter les métadonnées
    sanitizedData['createdAt'] = FieldValue.serverTimestamp();
    sanitizedData['updatedAt'] = FieldValue.serverTimestamp();
    sanitizedData['localId'] = operation.documentId;

    try {
      // Pour certaines collections (comme 'enterprises'), on veut utiliser l'ID existant
      // au lieu de générer un nouvel ID avec collection.add()
      // Vérifier si l'ID existe déjà dans les données (pour les entités avec ID prédéfini)
      final entityId = sanitizedData['id'] as String?;
      final useExistingId = entityId != null && 
                           entityId == operation.documentId &&
                           (operation.collectionName == 'enterprises' || 
                            operation.collectionName == 'users' ||
                            operation.collectionName == 'roles');
      
      DocumentReference docRef;
      String remoteId;
      
      if (useExistingId) {
        // Utiliser l'ID existant de l'entité
        docRef = collection.doc(entityId);
        await docRef.set(sanitizedData, SetOptions(merge: false));
        remoteId = entityId;
        
        developer.log(
          '✅ Created document with existing ID: $remoteId (collection: ${operation.collectionName}, path: ${collection.path})',
          name: 'offline.firebase',
        );
        
        // Pour les entreprises, le remoteId est déjà l'ID, donc pas besoin de mise à jour
        // Mais on peut quand même logger pour vérifier
        if (operation.collectionName == 'enterprises') {
          developer.log(
            '✅ Enterprise créée dans Firestore: id=$remoteId, name=${sanitizedData['name']}, type=${sanitizedData['type']}',
            name: 'offline.firebase',
          );
        }
      } else {
        // Générer un nouvel ID (comportement par défaut)
        docRef = await collection.add(sanitizedData);
        remoteId = docRef.id;
        
        developer.log(
          'Created document with new ID: $remoteId for ${operation.documentId}',
          name: 'offline.firebase',
        );
        
        // Mettre à jour le remoteId dans la base locale après création réussie
        // Cela permet aux futures mises à jour d'utiliser le bon remoteId
        final driftService = _driftService;
        if (driftService != null) {
          try {
            // Mettre à jour le remoteId (updateRemoteId ne nécessite pas le moduleType)
            await driftService.records.updateRemoteId(
              collectionName: operation.collectionName,
              localId: operation.documentId,
              remoteId: remoteId,
              serverUpdatedAt: DateTime.now(),
            );

            developer.log(
              'Updated remoteId for ${operation.documentId} -> $remoteId',
              name: 'offline.firebase',
            );
          } catch (e, stackTrace) {
            developer.log(
              'Error updating remoteId after create: $e',
              name: 'offline.firebase',
              error: e,
              stackTrace: stackTrace,
            );
            // Ne pas rethrow - la création a réussi, c'est juste la mise à jour du remoteId qui a échoué
            // Le remoteId sera mis à jour lors de la prochaine synchronisation
          }
        }
      }
    } on FirebaseException catch (e) {
      // Gestion spécifique des erreurs Firestore
      final errorMessage = _handleFirestoreError(e, operation);
      throw SyncException(errorMessage);
    }
  }

  Future<void> _handleUpdate(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    final docRef = collection.doc(operation.documentId);
    
    try {
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw SyncException(
          'Document ${operation.documentId} not found for update',
        );
      }

      // Sanitizer les données locales avant de les comparer/envoyer
      final rawLocalData = operation.payloadMap ?? {};
      final localData = DataSanitizer.sanitizeMap(rawLocalData);
      final serverData = docSnapshot.data() as Map<String, dynamic>?;

      // Si pas de données serveur, utiliser les données locales (déjà sanitizées)
      if (serverData == null) {
        final finalData = Map<String, dynamic>.from(localData)
          ..['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(finalData);
        developer.log(
          'Updated document ${operation.documentId} (no server data)',
          name: 'offline.firebase',
        );
        return;
      }

      // Vérifier les timestamps pour détecter les conflits
      final localUpdatedAtStr = localData['updatedAt'] as String?;
      final serverUpdatedAtStr = serverData['updatedAt'] as String?;

      final localUpdatedAt = localUpdatedAtStr != null
          ? DateTime.tryParse(localUpdatedAtStr)
          : null;
      final serverUpdatedAt = serverUpdatedAtStr != null
          ? DateTime.tryParse(serverUpdatedAtStr)
          : null;

      // Si Firestore est plus récent que la version locale, ne pas écraser
      // Mettre à jour la version locale avec Firestore à la place
      if (serverUpdatedAt != null &&
          localUpdatedAt != null &&
          serverUpdatedAt.isAfter(localUpdatedAt)) {
      developer.log(
        'Conflict detected: Firestore version is newer than local for ${operation.documentId}. '
        'Updating local data instead of overwriting Firestore.',
        name: 'offline.firebase',
      );

      // Mettre à jour la version locale avec la version Firestore
      final driftService = _driftService;
      if (driftService != null) {
        try {
          // Chercher l'enregistrement local existant pour obtenir le moduleType
          // On essaie de trouver par localId dans tous les modules possibles
          // En utilisant une liste de modules connus
          final knownModules = ['gaz', 'immobilier', 'boutique', 'eau_minerale', 'orange_money'];
          String? moduleType;

          for (final module in knownModules) {
            final record = await driftService.records.findByLocalId(
              collectionName: operation.collectionName,
              localId: operation.documentId,
              enterpriseId: operation.enterpriseId,
              moduleType: module,
            );
            if (record != null) {
              moduleType = record.moduleType;
              break;
            }
          }

          // Si pas trouvé par localId, essayer par remoteId
          if (moduleType == null) {
            for (final module in knownModules) {
              final record = await driftService.records.findByRemoteId(
                collectionName: operation.collectionName,
                remoteId: operation.documentId,
                enterpriseId: operation.enterpriseId,
                moduleType: module,
              );
              if (record != null) {
                moduleType = record.moduleType;
                break;
              }
            }
          }

          // Convertir les Timestamp Firestore en format JSON-compatible
          final serverDataJson = _convertToJsonCompatible(serverData);
          await driftService.records.upsert(
            collectionName: operation.collectionName,
            localId: operation.documentId,
            remoteId: operation.documentId,
            enterpriseId: operation.enterpriseId,
            moduleType: moduleType ?? '',
            dataJson: jsonEncode(serverDataJson),
            localUpdatedAt: DateTime.now(),
          );
          developer.log(
            'Local data updated with Firestore version for ${operation.documentId}',
            name: 'offline.firebase',
          );
        } catch (e, stackTrace) {
          developer.log(
            'Error updating local data with Firestore version: $e',
            name: 'offline.firebase',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Ne pas envoyer la modification locale vers Firestore
      // L'opération sera marquée comme synced car on a mis à jour localement
      return;
    }

      // Résoudre le conflit en utilisant ConflictResolver
      final finalData = conflictResolver.resolve(
        localData: localData,
        serverData: serverData,
      );

      // Vérifier si la résolution a choisi la version serveur
      // (dans ce cas, on n'a pas besoin de mettre à jour Firestore)
      final choseServer = finalData == serverData;
      if (choseServer) {
        developer.log(
          'Conflict resolved in favor of server for ${operation.documentId}. '
          'No update needed.',
          name: 'offline.firebase',
        );
        return;
      }

      // Sanitizer les données finales avant de les envoyer
      final sanitizedFinalData = DataSanitizer.sanitizeMap(finalData);
      sanitizedFinalData['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.update(sanitizedFinalData);

      developer.log(
        'Updated document ${operation.documentId} (conflict resolved)',
        name: 'offline.firebase',
      );
    } on FirebaseException catch (e) {
      // Gestion spécifique des erreurs Firestore
      final errorMessage = _handleFirestoreError(e, operation);
      throw SyncException(errorMessage);
    }
  }

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

  Future<void> _handleDelete(
    CollectionReference collection,
    SyncOperation operation,
  ) async {
    final docRef = collection.doc(operation.documentId);
    
    try {
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        developer.log(
          'Document ${operation.documentId} already deleted',
          name: 'offline.firebase',
        );
        return;
      }

      await docRef.delete();
      developer.log(
        'Deleted document ${operation.documentId}',
        name: 'offline.firebase',
      );
    } on FirebaseException catch (e) {
      // Gestion spécifique des erreurs Firestore
      // Pour delete, certaines erreurs peuvent être ignorées
      if (e.code == 'not-found') {
        developer.log(
          'Document ${operation.documentId} already deleted (not-found)',
          name: 'offline.firebase',
        );
        return; // Document déjà supprimé, considérer comme succès
      }
      
      final errorMessage = _handleFirestoreError(e, operation);
      throw SyncException(errorMessage);
    }
  }

  /// Gère les erreurs Firestore de manière spécifique.
  ///
  /// Retourne un message d'erreur approprié selon le code d'erreur Firestore.
  String _handleFirestoreError(
    FirebaseException e,
    SyncOperation operation,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission refusée pour ${operation.collectionName}/${operation.documentId}. '
            'Vérifiez les règles de sécurité Firestore et les permissions de l\'utilisateur.';

      case 'resource-exhausted':
        return 'Quota Firestore dépassé pour ${operation.collectionName}/${operation.documentId}. '
            'Veuillez réessayer plus tard ou contacter l\'administrateur.';

      case 'unauthenticated':
        return 'Non authentifié. Veuillez vous reconnecter.';

      case 'not-found':
        return 'Document ${operation.documentId} introuvable dans ${operation.collectionName}.';

      case 'already-exists':
        return 'Le document ${operation.documentId} existe déjà dans ${operation.collectionName}.';

      case 'failed-precondition':
        return 'Condition préalable échouée pour ${operation.collectionName}/${operation.documentId}. '
            'Le document a peut-être été modifié entre temps.';

      case 'aborted':
        return 'Opération annulée pour ${operation.collectionName}/${operation.documentId}. '
            'Réessayez.';

      case 'out-of-range':
        return 'Valeur hors limites pour ${operation.collectionName}/${operation.documentId}.';

      case 'unimplemented':
        return 'Opération non implémentée pour ${operation.collectionName}/${operation.documentId}.';

      case 'internal':
        return 'Erreur interne Firestore. Réessayez plus tard.';

      case 'unavailable':
        return 'Firestore temporairement indisponible. Réessayez plus tard.';

      case 'deadline-exceeded':
        return 'Timeout lors de l\'opération sur ${operation.collectionName}/${operation.documentId}. '
            'Réessayez.';

      case 'cancelled':
        return 'Opération annulée pour ${operation.collectionName}/${operation.documentId}.';

      default:
        return 'Erreur Firestore (${e.code}): ${e.message ?? "Erreur inconnue"} '
            'pour ${operation.collectionName}/${operation.documentId}.';
    }
  }
}

/// Mock sync handler for testing.
class MockSyncHandler implements SyncOperationHandler {
  MockSyncHandler({
    this.shouldFail = false,
    this.failureRate = 0.0,
    this.delayMs = 100,
  });

  final bool shouldFail;
  final double failureRate;
  final int delayMs;
  final List<SyncOperation> processedOperations = [];

  @override
  Future<void> processOperation(SyncOperation operation) async {
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    if (shouldFail) {
      throw SyncException('Mock sync failure');
    }

    if (failureRate > 0) {
      final random = DateTime.now().microsecond / 1000000;
      if (random < failureRate) {
        throw SyncException('Random mock failure');
      }
    }

    processedOperations.add(operation);
    developer.log(
      'Mock processed: ${operation.operationType} '
      '${operation.collectionName}/${operation.documentId}',
      name: 'offline.mock',
    );
  }

  void reset() {
    processedOperations.clear();
  }
}

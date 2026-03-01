import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../errors/error_handler.dart';
import '../../logging/app_logger.dart';

import '../drift/app_database.dart' show OfflineRecord;
import '../drift_service.dart';
import '../sync_manager.dart';
import '../sync_status.dart';
import '../sync/sync_conflict_resolver.dart';
import '../module_data_sync_service.dart';
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
    this.conflictResolver = const SyncConflictResolver(),
    DriftService? driftService,
  }) : _driftService = driftService;

  final FirebaseFirestore firestore;
  final Map<String, String Function(String? enterpriseId)> collectionPaths;
  final SyncConflictResolver conflictResolver;
  final DriftService? _driftService;

  @override
  Future<void> processOperation(SyncOperation operation) async {
    var collectionName = operation.collectionName;
    var effectiveEnterpriseId = operation.enterpriseId;
    
    // Legacy redirect for POS/Agence mistakenly queued to 'enterprises'
    // This unblocks operations queued before the path hierarchy fixes.
    if (collectionName == 'enterprises') {
      if (operation.documentId.startsWith('pos_')) {
        collectionName = 'pointOfSale';
        AppLogger.info(
          'Redirecting legacy POS sync operation ${operation.documentId} from "enterprises" to "pointOfSale"',
          name: 'offline.firebase',
        );
        // Extract parent ID from documentId: pos_{parentID}_{timestamp}
        if (effectiveEnterpriseId == 'global' || effectiveEnterpriseId.isEmpty) {
          final parts = operation.documentId.split('_');
          if (parts.length >= 3) {
            effectiveEnterpriseId = parts.sublist(1, parts.length - 1).join('_');
            AppLogger.debug('Extracted parent ID $effectiveEnterpriseId from legacy POS ID', name: 'offline.firebase');
          }
        }
      } else if (operation.documentId.startsWith('agence_')) {
        collectionName = 'agences';
        AppLogger.info(
          'Redirecting legacy Agence sync operation ${operation.documentId} from "enterprises" to "agences"',
          name: 'offline.firebase',
        );
        // Same for agences
        if (effectiveEnterpriseId == 'global' || effectiveEnterpriseId.isEmpty) {
          final parts = operation.documentId.split('_');
          if (parts.length >= 3) {
            effectiveEnterpriseId = parts.sublist(1, parts.length - 1).join('_');
            AppLogger.debug('Extracted parent ID $effectiveEnterpriseId from legacy Agence ID', name: 'offline.firebase');
          }
        }
      }
    }

    final pathBuilder = collectionPaths[collectionName];
    if (pathBuilder == null) {
      throw SyncException(
        'No path configured for collection: $collectionName',
      );
    }

    // Safety check: ensure effectiveEnterpriseId is never empty for sub-tenant paths
    if (collectionName != 'enterprises' && collectionName != 'users' && collectionName != 'roles' && collectionName != 'enterprise_module_users') {
      if (effectiveEnterpriseId.isEmpty || effectiveEnterpriseId == 'global') {
        throw SyncException(
          'Invalid enterpriseId ($effectiveEnterpriseId) for sub-tenant collection: $collectionName',
        );
      }
    }
    
    // Check if the collection is shared across sites (belongs to parent/company)
    final bool isSharedCollection = ModuleDataSyncService.sharedCollections.values
        .any((collections) => collections.contains(collectionName));

    if (isSharedCollection) {
      final parentId = await _getParentEnterpriseId(operation.enterpriseId);
      if (parentId != null) {
        effectiveEnterpriseId = parentId;
        AppLogger.debug(
          'Routing shared collection $collectionName to parent enterprise $parentId '
          '(from site ${operation.enterpriseId})',
          name: 'offline.firebase',
        );
      }
    }

    final collectionPath = pathBuilder(effectiveEnterpriseId);
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
        
        AppLogger.debug(
          '✅ Created document with existing ID: $remoteId (collection: ${operation.collectionName}, path: ${collection.path})',
          name: 'offline.firebase',
        );
        
        // Pour les entreprises, le remoteId est déjà l'ID, donc pas besoin de mise à jour
        // Mais on peut quand même logger pour vérifier
        if (operation.collectionName == 'enterprises') {
          AppLogger.debug(
            '✅ Enterprise créée dans Firestore: id=$remoteId, name=${sanitizedData['name']}, type=${sanitizedData['type']}',
            name: 'offline.firebase',
          );
        }
      } else {
        // Générer un nouvel ID (comportement par défaut)
        docRef = await collection.add(sanitizedData);
        remoteId = docRef.id;
        
        AppLogger.debug(
          'Created document with new ID: $remoteId for ${operation.documentId}',
          name: 'offline.firebase',
        );
        
        // Mettre à jour le remoteId dans la base locale après création réussie
        // Cela permet aux futures mises à jour d'utiliser le bon remoteId
        final driftService = _driftService;
        if (driftService != null) {
          try {
            await driftService.records.updateRemoteId(
              collectionName: operation.collectionName,
              localId: operation.documentId,
              remoteId: remoteId,
              serverUpdatedAt: DateTime.now(),
              enterpriseId: operation.enterpriseId,
            );

            AppLogger.debug(
              'Updated remoteId for ${operation.documentId} -> $remoteId',
              name: 'offline.firebase',
            );
          } catch (e, stackTrace) {
            AppLogger.error(
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
    
    // Sanitizer les données locales
    final rawLocalData = operation.payloadMap ?? {};
    final localData = DataSanitizer.sanitizeMap(rawLocalData);
    
    // Ajouter les métadonnées
    localData['updatedAt'] = FieldValue.serverTimestamp();
    localData['localId'] = operation.documentId;

    try {
      // Stratégie optimisée : set(merge: true) évite un docRef.get() initial.
      // C'est idéal pour le "Last Write Wins" et pour créer le document s'il manque.
      await docRef.set(localData, SetOptions(merge: true));
      
      AppLogger.debug(
        'Optimized update (set-merge) for: ${operation.collectionName}/${operation.documentId}',
        name: 'offline.firebase',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // En cas d'erreur de permission sur un set, on peut essayer de voir si c'est un conflit
        // ou un vrai problème de droits.
        final errorMessage = _handleFirestoreError(e, operation);
        throw SyncException(errorMessage);
      }
      
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
        AppLogger.debug(
          'Document ${operation.documentId} already deleted',
          name: 'offline.firebase',
        );
        return;
      }

      await docRef.delete();
      AppLogger.debug(
        'Deleted document ${operation.documentId}',
        name: 'offline.firebase',
      );
    } on FirebaseException catch (e) {
      // Gestion spécifique des erreurs Firestore
      // Pour delete, certaines erreurs peuvent être ignorées
      if (e.code == 'not-found') {
        AppLogger.debug(
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

  /// Récupère l'ID de l'entreprise parente pour un sous-tenant.
  Future<String?> _getParentEnterpriseId(String enterpriseId) async {
    final drift = _driftService;
    if (drift == null) return null;

    try {
      // On cherche l'enregistrement du point de vente/agence dans Drift
      // On teste les deux collections possibles pour les sous-tenants
      for (final collection in ['pointOfSale', 'agences']) {
        final record = await drift.records.findInCollectionByRemoteId(
          collectionName: collection,
          remoteId: enterpriseId,
        );

        if (record != null) {
          final decoded = jsonDecode(record.dataJson) as Map<String, dynamic>;
          return decoded['parentEnterpriseId'] as String?;
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Error looking up parent enterprise for $enterpriseId: $e',
        name: 'offline.firebase',
      );
    }
    return null;
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
    AppLogger.debug(
      'Mock processed: ${operation.operationType} '
      '${operation.collectionName}/${operation.documentId}',
      name: 'offline.mock',
    );
  }

  void reset() {
    processedOperations.clear();
  }
}

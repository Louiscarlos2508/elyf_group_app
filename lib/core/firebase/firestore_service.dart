import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Service générique pour accéder à Firestore avec support multi-tenant.
///
/// Ce service fournit des méthodes CRUD génériques pour toutes les collections
/// Firestore avec isolation par entreprise et module.
///
/// Structure des collections :
/// - `enterprises/{enterpriseId}/modules/{moduleId}/collections/{collectionName}`
/// - Ou `enterprises/{enterpriseId}/collections/{collectionName}` si pas de module
class FirestoreService {
  FirestoreService({
    required this.firestore,
  });

  final FirebaseFirestore firestore;

  /// Construit le chemin de collection avec enterpriseId et moduleId.
  ///
  /// Format : `enterprises/{enterpriseId}/modules/{moduleId}/collections/{collectionName}`
  /// Si moduleId est null : `enterprises/{enterpriseId}/collections/{collectionName}`
  String _buildCollectionPath({
    required String collectionName,
    required String enterpriseId,
    String? moduleId,
  }) {
    if (moduleId != null && moduleId.isNotEmpty) {
      return 'enterprises/$enterpriseId/modules/$moduleId/collections/$collectionName';
    }
    return 'enterprises/$enterpriseId/collections/$collectionName';
  }

  /// Construit le chemin de document avec enterpriseId et moduleId.
  String _buildDocumentPath({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
  }) {
    final collectionPath = _buildCollectionPath(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );
    return '$collectionPath/$documentId';
  }

  /// Crée ou met à jour un document dans Firestore.
  ///
  /// Si le document existe déjà, il sera mis à jour.
  /// Sinon, un nouveau document sera créé.
  ///
  /// Les champs `enterpriseId`, `moduleId` (si fourni), `updatedAt` sont
  /// automatiquement ajoutés/mis à jour.
  Future<void> setDocument({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      final docPath = _buildDocumentPath(
        collectionName: collectionName,
        documentId: documentId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      final docRef = firestore.doc(docPath);

      // Ajouter les métadonnées multi-tenant
      final dataWithMetadata = Map<String, dynamic>.from(data)
        ..['enterpriseId'] = enterpriseId
        ..['updatedAt'] = FieldValue.serverTimestamp();

      if (moduleId != null && moduleId.isNotEmpty) {
        dataWithMetadata['moduleId'] = moduleId;
      }

      // Si c'est une création, ajouter createdAt
      if (merge) {
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          dataWithMetadata['createdAt'] = FieldValue.serverTimestamp();
        }
      } else {
        dataWithMetadata['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(dataWithMetadata, SetOptions(merge: merge));

      developer.log(
        'Document set in Firestore: $docPath',
        name: 'firestore.service',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting document in Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère un document par son ID.
  Future<Map<String, dynamic>?> getDocument({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
  }) async {
    try {
      final docPath = _buildDocumentPath(
        collectionName: collectionName,
        documentId: documentId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      final docSnapshot = await firestore.doc(docPath).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return docSnapshot.data();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting document from Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Met à jour un document existant.
  ///
  /// Lance une exception si le document n'existe pas.
  Future<void> updateDocument({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docPath = _buildDocumentPath(
        collectionName: collectionName,
        documentId: documentId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      final dataWithMetadata = Map<String, dynamic>.from(data)
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await firestore.doc(docPath).update(dataWithMetadata);

      developer.log(
        'Document updated in Firestore: $docPath',
        name: 'firestore.service',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating document in Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Supprime un document.
  Future<void> deleteDocument({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
  }) async {
    try {
      final docPath = _buildDocumentPath(
        collectionName: collectionName,
        documentId: documentId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      await firestore.doc(docPath).delete();

      developer.log(
        'Document deleted from Firestore: $docPath',
        name: 'firestore.service',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting document from Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère tous les documents d'une collection.
  ///
  /// Optionnellement, peut filtrer par des critères supplémentaires.
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionName,
    required String enterpriseId,
    String? moduleId,
    Map<String, dynamic>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      final collectionPath = _buildCollectionPath(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      Query query = firestore.collection(collectionPath);

      // Appliquer les conditions where
      if (whereConditions != null) {
        for (final entry in whereConditions.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      // Appliquer le tri
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Appliquer la limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting collection from Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Écoute les changements d'une collection en temps réel.
  ///
  /// Retourne un Stream qui émet une liste de documents à chaque changement.
  Stream<List<Map<String, dynamic>>> watchCollection({
    required String collectionName,
    required String enterpriseId,
    String? moduleId,
    Map<String, dynamic>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      final collectionPath = _buildCollectionPath(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      Query query = firestore.collection(collectionPath);

      // Appliquer les conditions where
      if (whereConditions != null) {
        for (final entry in whereConditions.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      // Appliquer le tri
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Appliquer la limite
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data()..['id'] = doc.id)
            .toList();
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error watching collection from Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream.value([]);
    }
  }

  /// Écoute les changements d'un document en temps réel.
  Stream<Map<String, dynamic>?> watchDocument({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
  }) {
    try {
      final docPath = _buildDocumentPath(
        collectionName: collectionName,
        documentId: documentId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      return firestore.doc(docPath).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return snapshot.data()..['id'] = snapshot.id;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error watching document from Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream.value(null);
    }
  }

  /// Vérifie si un document existe.
  Future<bool> documentExists({
    required String collectionName,
    required String documentId,
    required String enterpriseId,
    String? moduleId,
  }) async {
    try {
      final docPath = _buildDocumentPath(
        collectionName: collectionName,
        documentId: documentId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      final docSnapshot = await firestore.doc(docPath).get();
      return docSnapshot.exists;
    } catch (e) {
      developer.log(
        'Error checking if document exists',
        name: 'firestore.service',
        error: e,
      );
      return false;
    }
  }

  /// Effectue une requête avec plusieurs conditions where.
  ///
  /// Permet de construire des requêtes complexes avec plusieurs filtres.
  Future<List<Map<String, dynamic>>> query({
    required String collectionName,
    required String enterpriseId,
    String? moduleId,
    List<MapEntry<String, dynamic>>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final collectionPath = _buildCollectionPath(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      Query query = firestore.collection(collectionPath);

      // Appliquer les conditions where
      if (whereConditions != null) {
        for (final condition in whereConditions) {
          if (condition.value is List) {
            // Support pour 'in' queries
            query = query.where(
              condition.key,
              whereIn: condition.value as List,
            );
          } else {
            query = query.where(condition.key, isEqualTo: condition.value);
          }
        }
      }

      // Appliquer le tri
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Appliquer la limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error querying Firestore',
        name: 'firestore.service',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}


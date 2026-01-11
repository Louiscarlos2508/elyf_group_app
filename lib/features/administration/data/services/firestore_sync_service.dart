import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, Timestamp, FieldValue, SetOptions, FirebaseException, Query;

import '../../../../core/offline/drift_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/enterprise.dart';
import '../../domain/entities/audit_log.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';

/// Service for syncing administration data with Firestore.
/// 
/// Handles bidirectional sync between Drift (offline) and Firestore (cloud).
class FirestoreSyncService {
  FirestoreSyncService({
    required this.driftService,
    required this.firestore,
  });

  final DriftService driftService;
  final FirebaseFirestore firestore;

  // Collection paths
  static const String _usersCollection = 'users';
  static const String _enterprisesCollection = 'enterprises';
  static const String _rolesCollection = 'roles';
  static const String _enterpriseModuleUsersCollection = 'enterprise_module_users';
  static const String _auditLogsCollection = 'audit_logs';

  /// Sync a user to Firestore
  Future<void> syncUserToFirestore(User user, {bool isUpdate = false}) async {
    try {
      final userDoc = firestore.collection(_usersCollection).doc(user.id);
      
      if (isUpdate) {
        await userDoc.update(user.toMap());
      } else {
        await userDoc.set(user.toMap(), SetOptions(merge: true));
      }

      // Note: Sync status is handled by the repository layer
      // We just ensure the data is synced to Firestore

      developer.log(
        'User synced to Firestore: ${user.id}',
        name: 'admin.firestore.sync',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing user to Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - sync errors should not break the app
    }
  }

  /// Sync an enterprise to Firestore
  Future<void> syncEnterpriseToFirestore(
    Enterprise enterprise, {
    bool isUpdate = false,
  }) async {
    try {
      final enterpriseDoc = firestore
          .collection(_enterprisesCollection)
          .doc(enterprise.id);

      if (isUpdate) {
        await enterpriseDoc.update(enterprise.toMap());
      } else {
        await enterpriseDoc.set(enterprise.toMap(), SetOptions(merge: true));
      }

      developer.log(
        'Enterprise synced to Firestore: ${enterprise.id}',
        name: 'admin.firestore.sync',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing enterprise to Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sync a role to Firestore
  /// 
  /// Throws an exception with a user-friendly message if the sync fails,
  /// especially for permission denied errors.
  Future<void> syncRoleToFirestore(UserRole role, {bool isUpdate = false}) async {
    try {
      final roleDoc = firestore.collection(_rolesCollection).doc(role.id);
      final roleMap = {
        'id': role.id,
        'name': role.name,
        'description': role.description,
        'permissions': role.permissions.toList(),
        'isSystemRole': role.isSystemRole,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isUpdate) {
        await roleDoc.update(roleMap);
      } else {
        await roleDoc.set(roleMap, SetOptions(merge: true));
      }

      developer.log(
        'Role synced to Firestore: ${role.id}',
        name: 'admin.firestore.sync',
      );
    } on FirebaseException catch (e, stackTrace) {
      developer.log(
        'Error syncing role to Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Propager les erreurs de permission avec un message clair
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission refusée : Vous n\'avez pas les droits pour créer/modifier des rôles dans Firestore. '
          'Vérifiez que :\n'
          '1. Votre utilisateur a le flag isAdmin: true dans Firestore\n'
          '2. Les règles de sécurité Firestore permettent l\'écriture dans la collection "roles"\n'
          '3. Votre utilisateur est bien authentifié avec Firebase Auth'
        );
      }
      
      // Propager les autres erreurs Firestore avec un message adapté
      throw Exception(
        'Erreur lors de la synchronisation avec Firestore: ${e.message ?? e.code}'
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing role to Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sync EnterpriseModuleUser to Firestore.
  Future<void> syncEnterpriseModuleUserToFirestore(
    EnterpriseModuleUser emu, {
    bool isUpdate = false,
  }) async {
    try {
      final docId = emu.documentId;
      final doc = firestore
          .collection(_enterpriseModuleUsersCollection)
          .doc(docId);

      final emuMap = emu.toMap()..['updatedAt'] = FieldValue.serverTimestamp();

      if (isUpdate) {
        await doc.update(emuMap);
      } else {
        await doc.set(emuMap, SetOptions(merge: true));
      }

      developer.log(
        'EnterpriseModuleUser synced to Firestore: $docId',
        name: 'admin.firestore.sync',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing EnterpriseModuleUser to Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete from Firestore
  /// 
  /// Throws an exception with a user-friendly message if the deletion fails,
  /// especially for permission denied errors.
  Future<void> deleteFromFirestore({
    required String collection,
    required String documentId,
  }) async {
    try {
      await firestore.collection(collection).doc(documentId).delete();

      developer.log(
        'Document deleted from Firestore: $collection/$documentId',
        name: 'admin.firestore.sync',
      );
    } on FirebaseException catch (e, stackTrace) {
      developer.log(
        'Error deleting from Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Propager les erreurs de permission avec un message clair
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission refusée : Vous n\'avez pas les droits pour supprimer dans Firestore. '
          'Vérifiez que :\n'
          '1. Votre utilisateur a le flag isAdmin: true dans Firestore\n'
          '2. Les règles de sécurité Firestore permettent la suppression dans la collection "$collection"\n'
          '3. Votre utilisateur est bien authentifié avec Firebase Auth'
        );
      }
      
      // Propager les autres erreurs Firestore avec un message adapté
      throw Exception(
        'Erreur lors de la suppression dans Firestore: ${e.message ?? e.code}'
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting from Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Pull users from Firestore
  /// 
  /// Récupère tous les utilisateurs depuis Firestore et les convertit en entités User.
  /// Gère les Timestamps Firestore et les convertit en DateTime.
  Future<List<User>> pullUsersFromFirestore() async {
    try {
      final snapshot = await firestore.collection(_usersCollection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convertir les Timestamps Firestore en DateTime
        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];
        
        return User(
          id: data['id'] as String? ?? doc.id,
          firstName: data['firstName'] as String? ?? '',
          lastName: data['lastName'] as String? ?? '',
          username: data['username'] as String? ?? data['email']?.split('@').first ?? '',
          email: data['email'] as String?,
          phone: data['phone'] as String?,
          isActive: data['isActive'] as bool? ?? true,
          createdAt: createdAt != null
              ? (createdAt is Timestamp
                  ? createdAt.toDate()
                  : DateTime.tryParse(createdAt.toString()))
              : null,
          updatedAt: updatedAt != null
              ? (updatedAt is Timestamp
                  ? updatedAt.toDate()
                  : DateTime.tryParse(updatedAt.toString()))
              : null,
        );
      }).toList();
    } on FirebaseException catch (e, stackTrace) {
      developer.log(
        'Firebase error pulling users from Firestore (code: ${e.code}): ${e.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error pulling users from Firestore: $e',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Pull enterprises from Firestore
  Future<List<Enterprise>> pullEnterprisesFromFirestore() async {
    try {
      final snapshot = await firestore.collection(_enterprisesCollection).get();
      return snapshot.docs
          .map((doc) => Enterprise.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error pulling enterprises from Firestore',
        name: 'admin.firestore.sync',
        error: e,
      );
      return [];
    }
  }

  /// Pull roles from Firestore
  Future<List<UserRole>> pullRolesFromFirestore() async {
    try {
      final snapshot = await firestore.collection(_rolesCollection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserRole(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String,
          permissions: (data['permissions'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toSet() ??
              {},
          isSystemRole: data['isSystemRole'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      developer.log(
        'Error pulling roles from Firestore',
        name: 'admin.firestore.sync',
        error: e,
      );
      return [];
    }
  }

  /// Pull EnterpriseModuleUsers from Firestore
  Future<List<EnterpriseModuleUser>> pullEnterpriseModuleUsersFromFirestore() async {
    try {
      final snapshot =
          await firestore.collection(_enterpriseModuleUsersCollection).get();
      return snapshot.docs
          .map((doc) => EnterpriseModuleUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error pulling EnterpriseModuleUsers from Firestore',
        name: 'admin.firestore.sync',
        error: e,
      );
      return [];
    }
  }

  /// Sync an audit log to Firestore
  /// 
  /// Enregistre un log d'audit dans Firestore pour la traçabilité et la conformité.
  /// Les logs d'audit sont critiques et doivent être sauvegardés dans le cloud.
  Future<void> syncAuditLogToFirestore(AuditLog log) async {
    try {
      final logDoc = firestore.collection(_auditLogsCollection).doc(log.id);
      
      final logMap = log.toMap()
        ..['timestamp'] = Timestamp.fromDate(log.timestamp);
      
      await logDoc.set(logMap, SetOptions(merge: true));

      // Note: Le remoteId sera géré automatiquement par le système de sync
      // si nécessaire. Pour les audit logs, on utilise l'ID local comme remoteId.

      developer.log(
        'Audit log synced to Firestore: ${log.id}',
        name: 'admin.firestore.sync',
      );
    } on FirebaseException catch (e, stackTrace) {
      developer.log(
        'Firebase error syncing audit log to Firestore (code: ${e.code}): ${e.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - les erreurs de sync ne doivent pas bloquer l'application
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing audit log to Firestore: $e',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - les erreurs de sync ne doivent pas bloquer l'application
    }
  }

  /// Pull audit logs from Firestore
  /// 
  /// Récupère les logs d'audit depuis Firestore, par exemple lors de la synchronisation initiale
  /// ou pour récupérer les logs depuis un autre appareil.
  Future<List<AuditLog>> pullAuditLogsFromFirestore({
    int? limit,
    DateTime? since,
  }) async {
    try {
      Query query = firestore.collection(_auditLogsCollection);
      
      if (since != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }
      
      query = query.orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null for audit log: ${doc.id}');
        }
        
        // Convertir le Timestamp Firestore en DateTime
        final timestamp = data['timestamp'];
        
        return AuditLog(
          id: data['id'] as String? ?? doc.id,
          action: AuditAction.values.firstWhere(
            (e) => e.name == data['action'] as String?,
            orElse: () => AuditAction.unknown,
          ),
          entityType: data['entityType'] as String? ?? '',
          entityId: data['entityId'] as String? ?? '',
          userId: data['userId'] as String? ?? '',
          timestamp: timestamp is Timestamp 
              ? timestamp.toDate() 
              : timestamp != null
                  ? DateTime.tryParse(timestamp.toString()) ?? DateTime.now()
                  : DateTime.now(),
          description: data['description'] as String?,
          oldValue: data['oldValue'] as Map<String, dynamic>?,
          newValue: data['newValue'] as Map<String, dynamic>?,
          moduleId: data['moduleId'] as String?,
          enterpriseId: data['enterpriseId'] as String?,
          userDisplayName: data['userDisplayName'] as String?,
        );
      }).toList();
    } on FirebaseException catch (e, stackTrace) {
      developer.log(
        'Firebase error pulling audit logs from Firestore (code: ${e.code}): ${e.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error pulling audit logs from Firestore: $e',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}


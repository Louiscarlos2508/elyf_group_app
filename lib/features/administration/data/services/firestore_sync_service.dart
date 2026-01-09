import 'dart:developer' as developer;
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/offline/drift_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/enterprise.dart';
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
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing role to Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting from Firestore',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Pull users from Firestore
  Future<List<User>> pullUsersFromFirestore() async {
    try {
      final snapshot = await firestore.collection(_usersCollection).get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error pulling users from Firestore',
        name: 'admin.firestore.sync',
        error: e,
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
}


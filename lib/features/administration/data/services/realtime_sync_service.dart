import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, QuerySnapshot, DocumentChangeType;

import '../../../../core/offline/drift_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/enterprise.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import 'firestore_sync_service.dart';

/// Service pour la synchronisation en temps réel depuis Firestore vers la base locale.
///
/// Écoute les changements dans Firestore et met à jour automatiquement la base locale.
class RealtimeSyncService {
  RealtimeSyncService({
    required this.driftService,
    required this.firestore,
    required this.firestoreSync,
  });

  final DriftService driftService;
  final FirebaseFirestore firestore;
  final FirestoreSyncService firestoreSync;

  // Collection paths
  static const String _usersCollection = 'users';
  static const String _enterprisesCollection = 'enterprises';
  static const String _rolesCollection = 'roles';
  static const String _enterpriseModuleUsersCollection =
      'enterprise_module_users';

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _enterprisesSubscription;
  StreamSubscription<QuerySnapshot>? _rolesSubscription;
  StreamSubscription<QuerySnapshot>? _enterpriseModuleUsersSubscription;

  bool _isListening = false;

  /// Démarre l'écoute en temps réel de toutes les collections.
  ///
  /// Met à jour automatiquement la base locale quand des changements
  /// sont détectés dans Firestore.
  Future<void> startRealtimeSync() async {
    if (_isListening) {
      developer.log(
        'RealtimeSyncService already listening',
        name: 'admin.realtime.sync',
      );
      return;
    }

    try {
      await _listenToUsers();
      await _listenToEnterprises();
      await _listenToRoles();
      await _listenToEnterpriseModuleUsers();

      _isListening = true;
      developer.log(
        'RealtimeSyncService started - listening to all collections',
        name: 'admin.realtime.sync',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error starting realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Arrête l'écoute en temps réel.
  Future<void> stopRealtimeSync() async {
    await _usersSubscription?.cancel();
    await _enterprisesSubscription?.cancel();
    await _rolesSubscription?.cancel();
    await _enterpriseModuleUsersSubscription?.cancel();

    _usersSubscription = null;
    _enterprisesSubscription = null;
    _rolesSubscription = null;
    _enterpriseModuleUsersSubscription = null;

    _isListening = false;
    developer.log('RealtimeSyncService stopped', name: 'admin.realtime.sync');
  }

  /// Écoute les changements dans la collection users.
  Future<void> _listenToUsers() async {
    try {
      _usersSubscription = firestore
          .collection(_usersCollection)
          .snapshots()
          .listen(
            (snapshot) async {
              for (final docChange in snapshot.docChanges) {
                try {
                  final data = docChange.doc.data();
                  if (data == null) continue;

                  final user = User.fromMap(Map<String, dynamic>.from(data));

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                    case DocumentChangeType.modified:
                      // Sauvegarder localement sans déclencher de sync
                      // (les données viennent de Firestore, pas besoin de les re-sync)
                      await _saveUserToLocal(user);
                      developer.log(
                        'User ${docChange.type.name} in realtime: ${user.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                    case DocumentChangeType.removed:
                      await _deleteUserFromLocal(user.id);
                      developer.log(
                        'User removed in realtime: ${user.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                  }
                } catch (e, stackTrace) {
                  developer.log(
                    'Error processing user change in realtime sync',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error) {
              developer.log(
                'Error in users realtime stream',
                name: 'admin.realtime.sync',
                error: error,
              );
            },
          );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting up users realtime listener',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Écoute les changements dans la collection enterprises.
  Future<void> _listenToEnterprises() async {
    try {
      _enterprisesSubscription = firestore
          .collection(_enterprisesCollection)
          .snapshots()
          .listen(
            (snapshot) async {
              for (final docChange in snapshot.docChanges) {
                try {
                  final data = docChange.doc.data();
                  if (data == null) continue;

                  final enterprise = Enterprise.fromMap(
                    Map<String, dynamic>.from(data),
                  );

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                    case DocumentChangeType.modified:
                      await _saveEnterpriseToLocal(enterprise);
                      developer.log(
                        'Enterprise ${docChange.type.name} in realtime: ${enterprise.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                    case DocumentChangeType.removed:
                      await _deleteEnterpriseFromLocal(enterprise.id);
                      developer.log(
                        'Enterprise removed in realtime: ${enterprise.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                  }
                } catch (e, stackTrace) {
                  developer.log(
                    'Error processing enterprise change in realtime sync',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error) {
              developer.log(
                'Error in enterprises realtime stream',
                name: 'admin.realtime.sync',
                error: error,
              );
            },
          );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting up enterprises realtime listener',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Écoute les changements dans la collection roles.
  Future<void> _listenToRoles() async {
    try {
      _rolesSubscription = firestore
          .collection(_rolesCollection)
          .snapshots()
          .listen(
            (snapshot) async {
              for (final docChange in snapshot.docChanges) {
                try {
                  final data = docChange.doc.data();
                  if (data == null) continue;

                  final roleData = Map<String, dynamic>.from(data);
                  final role = UserRole(
                    id: roleData['id'] as String,
                    name: roleData['name'] as String,
                    description: roleData['description'] as String,
                    permissions:
                        (roleData['permissions'] as List<dynamic>?)
                            ?.map((e) => e as String)
                            .toSet() ??
                        {},
                    isSystemRole: roleData['isSystemRole'] as bool? ?? false,
                  );

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                    case DocumentChangeType.modified:
                      await _saveRoleToLocal(role);
                      developer.log(
                        'Role ${docChange.type.name} in realtime: ${role.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                    case DocumentChangeType.removed:
                      await _deleteRoleFromLocal(role.id);
                      developer.log(
                        'Role removed in realtime: ${role.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                  }
                } catch (e, stackTrace) {
                  developer.log(
                    'Error processing role change in realtime sync',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error) {
              developer.log(
                'Error in roles realtime stream',
                name: 'admin.realtime.sync',
                error: error,
              );
            },
          );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting up roles realtime listener',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Écoute les changements dans la collection enterprise_module_users.
  Future<void> _listenToEnterpriseModuleUsers() async {
    try {
      _enterpriseModuleUsersSubscription = firestore
          .collection(_enterpriseModuleUsersCollection)
          .snapshots()
          .listen(
            (snapshot) async {
              for (final docChange in snapshot.docChanges) {
                try {
                  final data = docChange.doc.data();
                  if (data == null) continue;

                  final assignment = EnterpriseModuleUser.fromMap(
                    Map<String, dynamic>.from(data),
                  );

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                    case DocumentChangeType.modified:
                      await _saveEnterpriseModuleUserToLocal(assignment);
                      developer.log(
                        'EnterpriseModuleUser ${docChange.type.name} in realtime: ${assignment.documentId}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                    case DocumentChangeType.removed:
                      await _deleteEnterpriseModuleUserFromLocal(
                        assignment.documentId,
                      );
                      developer.log(
                        'EnterpriseModuleUser removed in realtime: ${assignment.documentId}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                  }
                } catch (e, stackTrace) {
                  developer.log(
                    'Error processing EnterpriseModuleUser change in realtime sync',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error) {
              developer.log(
                'Error in enterprise_module_users realtime stream',
                name: 'admin.realtime.sync',
                error: error,
              );
            },
          );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting up enterprise_module_users realtime listener',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sauvegarde un utilisateur localement (sans déclencher de sync).
  Future<void> _saveUserToLocal(User user) async {
    try {
      // Utiliser directement la méthode saveToLocal du repository
      // via FirestoreSyncService qui a accès aux repositories
      final map = user.toMap();
      await driftService.records.upsert(
        collectionName: _usersCollection,
        localId: user.id,
        remoteId: user.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving user to local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Supprime un utilisateur localement.
  Future<void> _deleteUserFromLocal(String userId) async {
    try {
      await driftService.records.deleteByLocalId(
        collectionName: _usersCollection,
        localId: userId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting user from local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sauvegarde une entreprise localement (sans déclencher de sync).
  Future<void> _saveEnterpriseToLocal(Enterprise enterprise) async {
    try {
      final map = enterprise.toMap();
      await driftService.records.upsert(
        collectionName: _enterprisesCollection,
        localId: enterprise.id,
        remoteId: enterprise.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving enterprise to local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Supprime une entreprise localement.
  Future<void> _deleteEnterpriseFromLocal(String enterpriseId) async {
    try {
      await driftService.records.deleteByLocalId(
        collectionName: _enterprisesCollection,
        localId: enterpriseId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting enterprise from local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sauvegarde un rôle localement (sans déclencher de sync).
  Future<void> _saveRoleToLocal(UserRole role) async {
    try {
      final map = {
        'id': role.id,
        'name': role.name,
        'description': role.description,
        'permissions': role.permissions.toList(),
        'isSystemRole': role.isSystemRole,
      };
      await driftService.records.upsert(
        collectionName: _rolesCollection,
        localId: role.id,
        remoteId: role.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving role to local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Supprime un rôle localement.
  Future<void> _deleteRoleFromLocal(String roleId) async {
    try {
      await driftService.records.deleteByLocalId(
        collectionName: _rolesCollection,
        localId: roleId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting role from local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sauvegarde une assignation localement (sans déclencher de sync).
  Future<void> _saveEnterpriseModuleUserToLocal(
    EnterpriseModuleUser assignment,
  ) async {
    try {
      final map = assignment.toMap();
      await driftService.records.upsert(
        collectionName: _enterpriseModuleUsersCollection,
        localId: assignment.documentId,
        remoteId: assignment.documentId,
        enterpriseId: assignment.enterpriseId,
        moduleType: assignment.moduleId,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving EnterpriseModuleUser to local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Supprime une assignation localement.
  Future<void> _deleteEnterpriseModuleUserFromLocal(String documentId) async {
    try {
      // Note: On ne peut pas supprimer par documentId seul car on a besoin de enterpriseId et moduleType
      // On va chercher d'abord l'enregistrement
      final record = await driftService.records.findByLocalId(
        collectionName: _enterpriseModuleUsersCollection,
        localId: documentId,
        enterpriseId:
            'global', // Peut être n'importe lequel, on cherche juste par localId
        moduleType: 'administration',
      );

      if (record != null) {
        await driftService.records.deleteByLocalId(
          collectionName: _enterpriseModuleUsersCollection,
          localId: documentId,
          enterpriseId: record.enterpriseId,
          moduleType: record.moduleType,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting EnterpriseModuleUser from local in realtime sync',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

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
  bool _initialPullCompleted = false;
  final Completer<void> _initialPullCompleter = Completer<void>();

  /// Démarre l'écoute en temps réel de toutes les collections.
  ///
  /// Fait d'abord un pull initial depuis Firestore vers Drift (offline-first),
  /// puis démarre l'écoute en temps réel pour les changements futurs.
  Future<void> startRealtimeSync() async {
    if (_isListening) {
      developer.log(
        'RealtimeSyncService already listening',
        name: 'admin.realtime.sync',
      );
      return;
    }

    try {
      // 1. Pull initial : charger toutes les données depuis Firestore vers Drift
      developer.log(
        'Starting initial pull from Firestore to Drift...',
        name: 'admin.realtime.sync',
      );
      await _pullInitialDataFromFirestore();

      // 2. Démarrer l'écoute en temps réel pour les changements futurs
      await _listenToUsers();
      await _listenToEnterprises();
      await _listenToRoles();
      await _listenToEnterpriseModuleUsers();

      _isListening = true;
      developer.log(
        'RealtimeSyncService started - initial pull completed, listening to all collections',
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

  /// Fait un pull initial de toutes les données depuis Firestore vers Drift.
  ///
  /// Cette méthode garantit que Drift contient toutes les données avant
  /// de démarrer l'écoute en temps réel (offline-first).
  Future<void> _pullInitialDataFromFirestore() async {
    try {
      // Pull des rôles
      final rolesSnapshot = await firestore.collection(_rolesCollection).get();
      for (final doc in rolesSnapshot.docs) {
        final data = doc.data();
        final role = UserRole(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String,
          permissions:
              (data['permissions'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toSet() ??
              {},
          isSystemRole: data['isSystemRole'] as bool? ?? false,
        );
        await _saveRoleToLocal(role);
      }
      developer.log(
        'Pulled ${rolesSnapshot.docs.length} roles from Firestore',
        name: 'admin.realtime.sync',
      );

      // Pull des EnterpriseModuleUsers
      final assignmentsSnapshot = await firestore
          .collection(_enterpriseModuleUsersCollection)
          .get();
      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        final assignment = EnterpriseModuleUser.fromMap(
          Map<String, dynamic>.from(data),
        );
        await _saveEnterpriseModuleUserToLocal(assignment);
      }
      developer.log(
        'Pulled ${assignmentsSnapshot.docs.length} EnterpriseModuleUsers from Firestore',
        name: 'admin.realtime.sync',
      );

      // Pull des utilisateurs
      final usersSnapshot = await firestore.collection(_usersCollection).get();
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final user = User.fromMap(Map<String, dynamic>.from(data));
        await _saveUserToLocal(user);
      }
      developer.log(
        'Pulled ${usersSnapshot.docs.length} users from Firestore',
        name: 'admin.realtime.sync',
      );

      // Pull des entreprises
      final enterprisesSnapshot = await firestore
          .collection(_enterprisesCollection)
          .get();
      for (final doc in enterprisesSnapshot.docs) {
        final data = doc.data();
        final enterprise = Enterprise.fromMap(Map<String, dynamic>.from(data));
        await _saveEnterpriseToLocal(enterprise);
      }
      developer.log(
        'Pulled ${enterprisesSnapshot.docs.length} enterprises from Firestore',
        name: 'admin.realtime.sync',
      );

      developer.log(
        'Initial pull from Firestore to Drift completed successfully',
        name: 'admin.realtime.sync',
      );

      _initialPullCompleted = true;
      if (!_initialPullCompleter.isCompleted) {
        _initialPullCompleter.complete();
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during initial pull from Firestore',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - on continue même si le pull initial échoue
      // L'écoute en temps réel chargera les données progressivement

      // Marquer quand même comme complété pour ne pas bloquer indéfiniment
      _initialPullCompleted = true;
      if (!_initialPullCompleter.isCompleted) {
        _initialPullCompleter.completeError(e);
      }
    }
  }

  /// Vérifie si le pull initial est terminé.
  bool get isInitialPullCompleted => _initialPullCompleted;

  /// Attend que le pull initial soit terminé.
  ///
  /// Retourne un Future qui se complète quand le pull initial est terminé
  /// ou après un timeout de 10 secondes maximum.
  Future<void> waitForInitialPull({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_initialPullCompleted) {
      return;
    }

    try {
      await _initialPullCompleter.future.timeout(timeout);
    } catch (e) {
      developer.log(
        'Timeout or error waiting for initial pull: $e',
        name: 'admin.realtime.sync',
      );
      // Ne pas rethrow - permettre à l'app de continuer même si le pull prend trop de temps
    }
  }

  /// Arrête l'écoute en temps réel.
  ///
  /// Note: Ne réinitialise PAS le flag _initialPullCompleted car les données
  /// (roles, entreprises, enterprise_module_users) sont partagées entre tous
  /// les utilisateurs et restent valides même après déconnexion.
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

  /// Vérifie si la synchronisation est en cours d'écoute.
  bool get isListening => _isListening;

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
      // Utiliser deleteByRemoteId car enterpriseId est le remoteId
      await driftService.records.deleteByRemoteId(
        collectionName: _enterprisesCollection,
        remoteId: enterpriseId,
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
      // Utiliser deleteByRemoteId car roleId est utilisé comme remoteId dans upsert
      await driftService.records.deleteByRemoteId(
        collectionName: _rolesCollection,
        remoteId: roleId,
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
        enterpriseId:
            'global', // EnterpriseModuleUsers sont globaux (pas liés à une entreprise spécifique dans le stockage)
        moduleType:
            'administration', // Tous les EnterpriseModuleUsers sont stockés avec moduleType='administration'
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
      // EnterpriseModuleUsers sont stockés avec enterpriseId='global' et moduleType='administration'
      // Le documentId est utilisé comme remoteId dans Drift
      await driftService.records.deleteByRemoteId(
        collectionName: _enterpriseModuleUsersCollection,
        remoteId: documentId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
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

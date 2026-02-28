import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, QuerySnapshot, DocumentSnapshot, DocumentChangeType, Timestamp, FirebaseException, FieldPath, GetOptions, Source;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rxdart/rxdart.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
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
  StreamSubscription<DocumentSnapshot>? _specificUserSubscription;
  // Map pour stocker les subscriptions des points de vente par entreprise (utilisé pour les non-admins)
  final Map<String, StreamSubscription<QuerySnapshot>> _pointOfSaleSubscriptions = {};
  
  // Nouveaux écouteurs globaux pour les admins
  StreamSubscription<QuerySnapshot>? _pointsOfSaleGroupSubscription;
  StreamSubscription<QuerySnapshot>? _agencesGroupSubscription;

  bool _isListening = false;

  /// Indique si le service écoute actuellement les changements.
  bool get isListening => _isListening;
  bool _initialPullCompleted = false;

  /// Completer pour attendre que le pull initial soit fini
  Completer<void>? _initialPullCompleter;

  /// Attend que la synchronisation initiale soit terminée.
  Future<void> waitForInitialPull() async {
    // Si déjà fini, retourner immédiatement
    if (_initialPullCompleted) return;
    
    // Si en cours, attendre le completer
    if (_initialPullCompleter != null) {
      return _initialPullCompleter!.future;
    }
    
    // Sinon, on ne peut pas encore attendre (start non appelé)
    // On attend un peu que start soit appelé ou on retourne
    // Note: C'est une sécurité, normalement start est appelé juste après login
  }

  void dispose() {
    _usersSubscription?.cancel();
    _enterprisesSubscription?.cancel();
    _rolesSubscription?.cancel();
    _enterpriseModuleUsersSubscription?.cancel();
    _specificUserSubscription?.cancel();
    for (final sub in _pointOfSaleSubscriptions.values) {
      sub.cancel();
    }
    _pointOfSaleSubscriptions.clear();
    _syncStatusController.close();
  }

  final _syncStatusController = StreamController<bool>.broadcast();
  bool _isSyncing = false;

  /// Stream indiquant si une synchronisation est en cours.
  Stream<bool> get syncStatusStream => _syncStatusController.stream;

  void _pulseSync() {
    _syncStatusController.add(true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_isSyncing) {
        _syncStatusController.add(false);
      }
    });
  }

  void _setSyncing(bool value) {
    _isSyncing = value;
    _syncStatusController.add(value);
  }

  String? _currentUserId;

  /// Arrête l'écoute en temps réel et libère les ressources.
  Future<void> stopRealtimeSync() async {
    _usersSubscription?.cancel();
    _enterprisesSubscription?.cancel();
    _rolesSubscription?.cancel();
    _enterpriseModuleUsersSubscription?.cancel();
    _specificUserSubscription?.cancel();
    for (final sub in _pointOfSaleSubscriptions.values) {
      sub.cancel();
    }
    _pointOfSaleSubscriptions.clear();
    
    _pointsOfSaleGroupSubscription?.cancel();
    _agencesGroupSubscription?.cancel();
    _pointsOfSaleGroupSubscription = null;
    _agencesGroupSubscription = null;
    
    _isListening = false;
    _initialPullCompleted = false;
    _currentUserId = null;
    
    developer.log(
      'RealtimeSyncService stopped',
      name: 'admin.realtime.sync',
    );
  }

  /// Démarre l'écoute en temps réel de toutes les collections.
  ///
  /// Fait d'abord un pull initial depuis Firestore vers Drift (offline-first),
  /// puis démarre l'écoute en temps réel pour les changements futurs.
  Future<void> startRealtimeSync({String? userId}) async {
    // Sur le Web, on n'utilise pas Drift pour l'admin, donc pas besoin de sync
    if (kIsWeb) {
      developer.log(
        'RealtimeSyncService: Skipping sync on Web (using direct Firestore)',
        name: 'admin.realtime.sync',
      );
      _isListening = true; // Simuler pour éviter les redémarrages
      _setSyncing(false);
      _initialPullCompleter = Completer<void>()..complete();
      return;
    }

    // Si déjà à l'écoute avec le même userId, ne rien faire
    if (_isListening && _currentUserId == userId) {
      developer.log(
        'RealtimeSyncService already listening for user: $userId',
        name: 'admin.realtime.sync',
      );
      return;
    }

    // Si on change d'utilisateur (ou si on passe d'anonyme à connecté), 
    // arrêter les anciennes subscriptions d'abord
    if (_isListening) {
      developer.log(
        'Restarting RealtimeSyncService for new user: $userId',
        name: 'admin.realtime.sync',
      );
      await stopRealtimeSync();
    }
    
    _currentUserId = userId;

    _setSyncing(true);
    _initialPullCompleter = Completer<void>();

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
      await _listenToSubTenants();

      _isListening = true;
      _setSyncing(false);
      
      // Signaler la fin du pull initial
      if (_initialPullCompleter != null && !_initialPullCompleter!.isCompleted) {
        _initialPullCompleter!.complete();
      }

      developer.log(
        'RealtimeSyncService started - initial pull completed, listening to all collections',
        name: 'admin.realtime.sync',
      );
    } catch (e, stackTrace) {
      _setSyncing(false);
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error starting realtime sync: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
       // S'assurer que le completer est libéré même en cas d'erreur
       if (_initialPullCompleter != null && !_initialPullCompleter!.isCompleted) {
        _initialPullCompleter!.complete();
      }
    }
  }

  /// Pull initial depuis Firestore (One-time fetch).
  Future<void> _pullInitialDataFromFirestore() async {
    try {
      if (_initialPullCompleted) return;

      // Utiliser le service de synchro existant qui gère déjà bien le pull initial
      await firestoreSync.pullInitialData(userId: _currentUserId);
      
      _initialPullCompleted = true;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error during initial pull from Firestore: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow ici pour permettre le démarrage de l'écoute temps réel
      // même si le pull initial échoue partiellement
    }
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

                  // Ajouter l'ID au map si absent
                  final userData = Map<String, dynamic>.from(data);
                  if (!userData.containsKey('id')) {
                    userData['id'] = docChange.doc.id;
                  }

                  final user = User.fromMap(userData);

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                    case DocumentChangeType.modified:
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
                  _pulseSync();
                } catch (e, stackTrace) {
                  // Loguer l'erreur mais continuer pour les autres changements
                  AppLogger.warning(
                    'Error processing user change in realtime sync: $e',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error, stackTrace) {
              if (error is FirebaseException && error.code == 'permission-denied') {
                developer.log('Permission denied for reading ALL users. Falling back to specific user query.', name: 'admin.realtime.sync');
                if (_currentUserId != null) {
                  _listenToSpecificUser(_currentUserId!);
                }
              } else {
                final appException = ErrorHandler.instance.handleError(error, stackTrace);
                AppLogger.error(
                  'Error in users realtime stream: ${appException.message}',
                  name: 'admin.realtime.sync',
                  error: error,
                  stackTrace: stackTrace,
                );
              }
            },
          );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up users realtime listener: ${appException.message}',
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

                  // Ajouter l'ID au map si absent
                  final enterpriseData = Map<String, dynamic>.from(data);
                  if (!enterpriseData.containsKey('id')) {
                    enterpriseData['id'] = docChange.doc.id;
                  }

                  final enterprise = Enterprise.fromMap(enterpriseData);

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                      // Pour une nouvelle entreprise, on doit aussi commencer à écouter ses points de vente
                      await _saveEnterpriseToLocal(enterprise);
                      await _listenToSubTenantsForEnterprise(enterprise.id);
                      developer.log(
                        'Enterprise added in realtime: ${enterprise.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                    case DocumentChangeType.modified:
                      await _saveEnterpriseToLocal(enterprise);
                      developer.log(
                        'Enterprise modified in realtime: ${enterprise.id}',
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
                  _pulseSync();
                } catch (e, stackTrace) {
                  AppLogger.warning(
                    'Error processing enterprise change in realtime sync: $e',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error, stackTrace) {
              if (error is FirebaseException && error.code == 'permission-denied') {
                developer.log('Permission denied for reading ALL enterprises. Falling back to assigned enterprises.', name: 'admin.realtime.sync');
                _listenToAssignedEnterprises();
              } else {
                final appException = ErrorHandler.instance.handleError(error, stackTrace);
                AppLogger.error(
                  'Error in enterprises realtime stream: ${appException.message}',
                  name: 'admin.realtime.sync',
                  error: error,
                  stackTrace: stackTrace,
                );
              }
            },
          );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up enterprises realtime listener: ${appException.message}',
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
                  // Assurer que l'ID est présent
                  if (!roleData.containsKey('id')) {
                    roleData['id'] = docChange.doc.id;
                  }
                  
                  // Récupérer le timestamp de modification pour la gestion des conflits
                  final firestoreUpdatedAt = _getTimestampFromData(roleData);

                  final role = UserRole.fromMap(roleData);

                  switch (docChange.type) {
                    case DocumentChangeType.added:
                    case DocumentChangeType.modified:
                      // Vérifier si la mise à jour est nécessaire (conflit)
                      if (await _shouldUpdateRoleFromFirestore(
                        roleId: role.id,
                        firestoreUpdatedAt: firestoreUpdatedAt,
                      )) {
                        await _saveRoleToLocal(
                          role, 
                          firestoreUpdatedAt: firestoreUpdatedAt,
                        );
                        developer.log(
                          'Role ${docChange.type.name} in realtime: ${role.id}',
                          name: 'admin.realtime.sync',
                        );
                      }
                      break;
                    case DocumentChangeType.removed:
                      await _deleteRoleFromLocal(role.id);
                      developer.log(
                        'Role removed in realtime: ${role.id}',
                        name: 'admin.realtime.sync',
                      );
                      break;
                  }
                  _pulseSync();
                } catch (e, stackTrace) {
                  AppLogger.warning(
                    'Error processing role change in realtime sync: $e',
                    name: 'admin.realtime.sync',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              }
            },
            onError: (error, stackTrace) {
              final appException = ErrorHandler.instance.handleError(error, stackTrace);
              AppLogger.error(
                'Error in roles realtime stream: ${appException.message}',
                name: 'admin.realtime.sync',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up roles realtime listener: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Écoute les changements dans la collection enterprise_module_users.
  /// Implemente une stratégie de repli (fallback) :
  /// 1. Tente d'écouter TOUS les documents (nécessite droits Admin)
  /// 2. En cas d'erreur de permission, tente d'écouter SEULEMENT les documents de l'utilisateur
  Future<void> _listenToEnterpriseModuleUsers() async {
    try {
      // Fonction helper pour traiter les snapshots
      Future<void> handleSnapshot(QuerySnapshot snapshot) async {
        for (final docChange in snapshot.docChanges) {
          try {
            final data = docChange.doc.data();
            if (data == null) continue;

            final assignment = EnterpriseModuleUser.fromMap(
              Map<String, dynamic>.from(data as Map),
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
            _pulseSync();
          } catch (e, stackTrace) {
            final appException = ErrorHandler.instance.handleError(e, stackTrace);
            AppLogger.warning(
              'Error processing EnterpriseModuleUser change in realtime sync: ${appException.message}',
              name: 'admin.realtime.sync',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }

      // Tentative 1: Écouter TOUS les documents (Admin)
      _enterpriseModuleUsersSubscription = firestore
          .collection(_enterpriseModuleUsersCollection)
          .snapshots()
          .listen(
            handleSnapshot,
            onError: (error, stackTrace) {
              // Vérifier si c'est une erreur de permission
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                
                developer.log(
                  'Permission denied for reading ALL enterprise_module_users. Falling back to user-specific query.',
                  name: 'admin.realtime.sync',
                  error: error,
                );

                // Tentative 2: Fallback sur l'utilisateur courant si disponible
                if (_currentUserId != null) {
                  _retryListenToUserEnterpriseModuleUsers(handleSnapshot);
                } else {
                   AppLogger.warning(
                    'Permission denied and no currentUserId available for fallback query.',
                    name: 'admin.realtime.sync',
                  );
                }
              } else {
                final appException =
                    ErrorHandler.instance.handleError(error, stackTrace);
                AppLogger.error(
                  'Error in enterprise_module_users realtime stream: ${appException.message}',
                  name: 'admin.realtime.sync',
                  error: error,
                  stackTrace: stackTrace,
                );
              }
            },
          );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up enterprise_module_users realtime listener: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Helper pour écouter seulement les assignations de l'utilisateur courant
  void _retryListenToUserEnterpriseModuleUsers(
    Function(QuerySnapshot) onSnapshot,
  ) {
    if (_currentUserId == null) return;

    // Annuler la souscription précédente qui a échoué
    _enterpriseModuleUsersSubscription?.cancel();

    developer.log(
      'Starting filtered sync for user: $_currentUserId',
      name: 'admin.realtime.sync',
    );

    try {
      _enterpriseModuleUsersSubscription = firestore
          .collection(_enterpriseModuleUsersCollection)
          .where('userId', isEqualTo: _currentUserId)
          .snapshots()
          .listen(
            (snapshot) => onSnapshot(snapshot),
            onError: (error, stackTrace) {
              final appException =
                  ErrorHandler.instance.handleError(error, stackTrace);
              AppLogger.error(
                'Error in user-specific enterprise_module_users realtime stream: ${appException.message}',
                name: 'admin.realtime.sync',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error setting up user-specific listener fallback',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _listenToSpecificUser(String userId) {
    _specificUserSubscription?.cancel();
    _specificUserSubscription = firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .listen((docSnapshot) async {
      try {
        final data = docSnapshot.data();
        if (data == null) return;
        final userData = Map<String, dynamic>.from(data);
        if (!userData.containsKey('id')) userData['id'] = docSnapshot.id;
        final user = User.fromMap(userData);
        await _saveUserToLocal(user);
        _pulseSync();
      } catch (e) {
        AppLogger.warning('Error in specific user listener: $e', name: 'admin.realtime.sync');
      }
    }, onError: (error, _) {
       AppLogger.warning('Listen failed for specific user: $error', name: 'admin.realtime.sync');
    });
  }

  Future<void> _listenToAssignedEnterprises() async {
    if (_currentUserId == null) return;
    _enterprisesSubscription?.cancel();

    try {
      // Obtenir les assignations pour connaître les entreprises
      final assignmentsSnapshot = await firestore
          .collection(_enterpriseModuleUsersCollection)
          .where('userId', isEqualTo: _currentUserId)
          .get(const GetOptions(source: Source.server));
          
      final Set<String> enterpriseIds = {};
      for (final doc in assignmentsSnapshot.docs) {
         final data = doc.data();
         if (data.containsKey('enterpriseId')) {
            enterpriseIds.add(data['enterpriseId'].toString());
         }
      }
      
      if (enterpriseIds.isEmpty) return;

      // Filter out what we already have or focus on what's missing
      // For now, let's just use individual listeners for stability with sub-collections
      for (var id in enterpriseIds) {
        final idStr = id.toString();
        
        // Root enterprise listener
        firestore.collection(_enterprisesCollection).doc(idStr).snapshots().listen((doc) async {
          if (doc.exists) {
            final data = doc.data()!;
            final enterpriseData = Map<String, dynamic>.from(data);
            if (!enterpriseData.containsKey('id')) enterpriseData['id'] = doc.id;
            await _saveEnterpriseToLocal(Enterprise.fromMap(enterpriseData));
            _pulseSync();
          } else {
            // If not in root, it might be a sub-tenant
            // Avoid collectionGroup(subName).where(FieldPath.documentId, isEqualTo: idStr) 
            // as it causes IllegalArgumentException on some platforms if it's a single segment ID.
            
            // Try to deduce parent if it follows our naming convention pos_PARENT_...
            String? deducedParent;
            String? subCollName;
            if (idStr.startsWith('pos_')) {
              final parts = idStr.split('_');
              if (parts.length >= 3) {
                deducedParent = '${parts[1]}_${parts[2]}';
                subCollName = 'pointsOfSale';
              }
            } else if (idStr.startsWith('agence_')) {
              final parts = idStr.split('_');
              if (parts.length >= 3) {
                deducedParent = '${parts[1]}_${parts[2]}';
                subCollName = 'agences';
              }
            }

            if (deducedParent != null && subCollName != null) {
              firestore.collection(_enterprisesCollection)
                  .doc(deducedParent)
                  .collection(subCollName)
                  .doc(idStr)
                  .snapshots()
                  .listen((doc) async {
                if (doc.exists) {
                  final data = Map<String, dynamic>.from(doc.data()!);
                  final enterprise = Enterprise.fromMap({
                    ...data,
                    'id': doc.id,
                    'parentEnterpriseId': deducedParent
                  });
                  await _saveEnterpriseToLocal(enterprise);
                  _pulseSync();
                }
              }, onError: (error, _) {
                AppLogger.warning('Listen failed for $subCollName/$idStr: $error', name: 'admin.realtime.sync');
              });
            } else {
              // Final fallback using a standard 'where' if we have 'id' field
              // instead of FieldPath.documentId to avoid segments error.
              for (final subName in ['pointsOfSale', 'agences']) {
                firestore.collectionGroup(subName)
                  .where('id', isEqualTo: idStr)
                  .snapshots()
                  .listen((snapshot) async {
                    if (snapshot.docs.isNotEmpty) {
                      final doc = snapshot.docs.first;
                      final data = Map<String, dynamic>.from(doc.data());
                      final parentId = doc.reference.parent.parent?.id;
                      if (parentId != null) {
                        final enterprise = Enterprise.fromMap({
                          ...data, 
                          'id': doc.id, 
                          'parentEnterpriseId': parentId
                        });
                        await _saveEnterpriseToLocal(enterprise);
                        _pulseSync();
                      }
                    }
                  }, onError: (error, _) {
                    // This is expected to fail for non-admins on collectionGroup
                  });
              }
            }
          }
        }, onError: (error, _) {
          AppLogger.warning('Listen failed for enterprise $idStr: $error', name: 'admin.realtime.sync');
        });
      }
    } catch (e) {
      AppLogger.warning('Error setting up assigned enterprises listener: $e', name: 'admin.realtime.sync');
    }
  }

  Future<void> _handleEnterpriseSnapshot(QuerySnapshot snapshot) async {
    for (final docChange in snapshot.docChanges) {
      try {
        final data = docChange.doc.data();
        if (data == null) continue;
        final enterpriseData = Map<String, dynamic>.from(data as Map);
        if (!enterpriseData.containsKey('id')) enterpriseData['id'] = docChange.doc.id;
        final enterprise = Enterprise.fromMap(enterpriseData);
        
        if (docChange.type == DocumentChangeType.removed) {
          await _deleteEnterpriseFromLocal(enterprise.id);
        } else {
          await _saveEnterpriseToLocal(enterprise);
        }
        _pulseSync();
      } catch (e) {
        AppLogger.warning('Error processing enterprise change: $e', name: 'admin.realtime.sync');
      }
    }
  }

  /// Sauvegarde un utilisateur localement (sans déclencher de sync).

  Future<void> _saveUserToLocal(User user) async {
    try {
      // Rechercher si on a déjà cet utilisateur avec un localId différent
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: _usersCollection,
        remoteId: user.id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final localId = existingRecord?.localId ?? user.id;
      final map = user.toMap();
      
      await driftService.records.upsert(
        collectionName: _usersCollection,
        localId: localId,
        remoteId: user.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error saving user to local in realtime sync: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error deleting user from local in realtime sync: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sauvegarde une entreprise localement (sans déclencher de sync).
  Future<void> _saveEnterpriseToLocal(Enterprise enterprise) async {
    try {
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: _enterprisesCollection,
        remoteId: enterprise.id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final localId = existingRecord?.localId ?? enterprise.id;
      final map = enterprise.toMap();
      
      await driftService.records.upsert(
        collectionName: _enterprisesCollection,
        localId: localId,
        remoteId: enterprise.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error saving enterprise to local in realtime sync: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error deleting enterprise from local in realtime sync: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Vérifie si on doit mettre à jour le rôle depuis Firestore.
  ///
  /// Retourne true si:
  /// - Le rôle n'existe pas localement
  /// - La version Firestore est plus récente que la version locale
  Future<bool> _shouldUpdateRoleFromFirestore({
    required String roleId,
    DateTime? firestoreUpdatedAt,
  }) async {
    try {
      // Récupérer l'enregistrement local existant
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: _rolesCollection,
        remoteId: roleId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      // Si le rôle n'existe pas localement, on doit le créer
      if (existingRecord == null) {
        return true;
      }

      // Si pas de timestamp Firestore, on accepte la mise à jour
      // (pour éviter de bloquer les mises à jour si le timestamp est manquant)
      if (firestoreUpdatedAt == null) {
        developer.log(
          'No Firestore updatedAt for role $roleId, accepting update',
          name: 'admin.realtime.sync',
        );
        return true;
      }

      // Comparer les timestamps : si la version locale est plus récente, ne pas écraser
      final localUpdatedAt = existingRecord.localUpdatedAt;
      if (localUpdatedAt.isAfter(firestoreUpdatedAt)) {
        developer.log(
          'Local version is newer for role $roleId: local=$localUpdatedAt, firestore=$firestoreUpdatedAt',
          name: 'admin.realtime.sync',
        );
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error checking if should update role from Firestore: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, accepter la mise à jour pour éviter de bloquer la synchronisation
      return true;
    }
  }

  /// Extrait le timestamp updatedAt depuis les données Firestore.
  DateTime? _getTimestampFromData(Map<String, dynamic> data) {
    try {
      final updatedAt = data['updatedAt'];
      if (updatedAt == null) return null;

      // Si c'est un Timestamp Firestore, le convertir
      if (updatedAt is Timestamp) {
        return updatedAt.toDate();
      }

      // Si c'est une chaîne ISO, la parser
      if (updatedAt is String) {
        return DateTime.parse(updatedAt);
      }

      return null;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error parsing updatedAt timestamp: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Sauvegarde un rôle localement (sans déclencher de sync).
  ///
  /// Pour les mises à jour depuis Firestore, utilise le timestamp Firestore
  /// au lieu de DateTime.now() pour préserver l'ordre chronologique.
  Future<void> _saveRoleToLocal(
    UserRole role, {
    DateTime? firestoreUpdatedAt,
  }) async {
    try {
      final map = {
        'id': role.id,
        'name': role.name,
        'description': role.description,
        'permissions': role.permissions.toList(),
        'isSystemRole': role.isSystemRole,
      };
      
      // Rechercher le localId existant
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: _rolesCollection,
        remoteId: role.id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final localId = existingRecord?.localId ?? role.id;
      
      // Utiliser le timestamp Firestore si fourni, sinon utiliser maintenant
      // Cela permet de préserver l'ordre chronologique des modifications
      final localUpdatedAt = firestoreUpdatedAt ?? DateTime.now();
      
      await driftService.records.upsert(
        collectionName: _rolesCollection,
        localId: localId,
        remoteId: role.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: localUpdatedAt,
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error saving role to local in realtime sync: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error deleting role from local in realtime sync: ${appException.message}',
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
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: _enterpriseModuleUsersCollection,
        remoteId: assignment.documentId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final localId = existingRecord?.localId ?? assignment.documentId;
      final map = assignment.toMap();
      
      await driftService.records.upsert(
        collectionName: _enterpriseModuleUsersCollection,
        localId: localId,
        remoteId: assignment.documentId,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error saving EnterpriseModuleUser to local in realtime sync: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error deleting EnterpriseModuleUser from local in realtime sync: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Écoute les changements dans les sous-collections (pointsOfSale, agences) de toutes les entreprises.
  Future<void> _listenToSubTenants() async {
    try {
      // 1. D'abord, vérifier si on est admin (simplifié : si userId est null c'est admin, 
      // ou on peut faire une vérification plus poussée si besoin)
      final bool useGlobalGroup = _currentUserId == null; // Désactivation pour les non-admins
      
      if (useGlobalGroup) {
        developer.log(
          'Setting up GLOBAL collectionGroup listeners for sub-tenants',
          name: 'admin.realtime.sync',
        );
        
        _pointsOfSaleGroupSubscription = firestore
            .collectionGroup('pointsOfSale')
            .snapshots()
            .listen(
              (snapshot) => _handleSubTenantSnapshot(snapshot, 'pointsOfSale'),
              onError: (error, stackTrace) {
                developer.log('Error in pointsOfSale collectionGroup: $error', name: 'admin.realtime.sync');
                // Si échec permission, on peut tenter le mode itératif
              }
            );
            
        _agencesGroupSubscription = firestore
            .collectionGroup('agences')
            .snapshots()
            .listen(
              (snapshot) => _handleSubTenantSnapshot(snapshot, 'agences'),
              onError: (error, stackTrace) {
                developer.log('Error in agences collectionGroup: $error', name: 'admin.realtime.sync');
              }
            );
            
        return;
      }

      // Mode itératif (legacy / fallback)
      final enterprisesSnapshot = await firestore
          .collection(_enterprisesCollection)
          .get();
      
      developer.log(
        'Setting up ITERATIVE realtime listeners for sub-tenants in ${enterprisesSnapshot.docs.length} enterprises',
        name: 'admin.realtime.sync',
      );
      
      for (final enterpriseDoc in enterprisesSnapshot.docs) {
        final enterpriseId = enterpriseDoc.id;
        await _listenToSubTenantsForEnterprise(enterpriseId);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        developer.log(
          'Permission denied reading ALL enterprises for sub-tenants. Falling back to assigned enterprises.',
          name: 'admin.realtime.sync',
        );
        if (_currentUserId == null) return;
        try {
          final userDoc = await firestore.collection(_usersCollection).doc(_currentUserId).get(GetOptions(source: Source.server));
          if (userDoc.exists) {
            final enterpriseIds = (userDoc.data()?['enterpriseIds'] as List<dynamic>?) ?? [];
            for (var id in enterpriseIds) {
              final idStr = id.toString();
              // Si l'ID est déjà un sous-tenant, inutile d'écouter la collection parente
              if (!idStr.startsWith('pos_') && !idStr.startsWith('agence_')) {
                await _listenToSubTenantsForEnterprise(idStr);
              }
            }
          }
        } catch (fallbackError) {
          developer.log(
            'Error setting up assigned enterprises sub-tenants listeners: $fallbackError',
            name: 'admin.realtime.sync',
          );
        }
      } else {
        rethrow;
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up sub-tenants realtime listeners: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gère les snapshots provenant de collectionGroup
  Future<void> _handleSubTenantSnapshot(QuerySnapshot snapshot, String subName) async {
    final moduleType = subName == 'pointsOfSale' ? 'gaz' : 'mobile_money';
    final collectionName = subName == 'pointsOfSale' ? 'pointOfSale' : 'agences';
    
    for (final docChange in snapshot.docChanges) {
      try {
        final data = docChange.doc.data();
        if (data == null) continue;
        
        final parentId = docChange.doc.reference.parent.parent?.id;
        if (parentId == null) {
          developer.log('Warning: No parentId found for sub-tenant ${docChange.doc.id}', name: 'admin.realtime.sync');
          continue;
        }

        final posData = Map<String, dynamic>.from(data as Map<String, dynamic>)
          ..['id'] = docChange.doc.id
          ..['parentEnterpriseId'] = parentId;

        final enterprise = Enterprise.fromMap(posData);

        switch (docChange.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await _saveEnterpriseSubTenantToLocal(
              enterprise, 
              parentId, 
              collectionName, 
              moduleType,
            );
            developer.log(
              'Sub-tenant $subName ${docChange.type.name} in realtime: ${enterprise.id}',
              name: 'admin.realtime.sync',
            );
            break;
          case DocumentChangeType.removed:
            await driftService.records.deleteByRemoteId(
              collectionName: collectionName,
              remoteId: enterprise.id,
              enterpriseId: parentId,
              moduleType: moduleType,
            );
            developer.log(
              'Sub-tenant $subName removed in realtime: ${enterprise.id}',
              name: 'admin.realtime.sync',
            );
            break;
        }
        _pulseSync();
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Error processing sub-tenant $subName change: $e',
          name: 'admin.realtime.sync',
          error: e,
        );
      }
    }
  }

  /// Sauvegarde un sous-tenant localement
  Future<void> _saveEnterpriseSubTenantToLocal(
    Enterprise enterprise,
    String parentId,
    String collectionName,
    String moduleType,
  ) async {
    final existingRecord = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: enterprise.id,
      enterpriseId: parentId,
      moduleType: moduleType,
    );

    final localId = existingRecord?.localId ?? enterprise.id;

    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: enterprise.id,
      enterpriseId: parentId,
      moduleType: moduleType,
      dataJson: jsonEncode(enterprise.toMap()),
      localUpdatedAt: DateTime.now(),
    );
  }

  /// Écoute les changements dans les sous-collections d'une entreprise spécifique.
  Future<void> _listenToSubTenantsForEnterprise(String enterpriseId) async {
    if (_pointOfSaleSubscriptions.containsKey(enterpriseId)) {
      return;
    }
    
    final List<StreamSubscription> subs = [];
    
    for (final subName in ['pointsOfSale', 'agences']) {
      final moduleType = subName == 'pointsOfSale' ? 'gaz' : 'mobile_money';
      final collectionName = subName == 'pointsOfSale' ? 'pointOfSale' : 'agences';

      try {
        final collection = firestore
            .collection(_enterprisesCollection)
            .doc(enterpriseId)
            .collection(subName);
        
        final subscription = collection.snapshots().listen(
          (snapshot) async {
            for (final docChange in snapshot.docChanges) {
              try {
                final data = docChange.doc.data();
                if (data == null) continue;

                final posData = Map<String, dynamic>.from(data)
                  ..['id'] = docChange.doc.id
                  ..['parentEnterpriseId'] = enterpriseId;

                switch (docChange.type) {
                  case DocumentChangeType.added:
                  case DocumentChangeType.modified:
                    final existingRecord = await driftService.records.findByRemoteId(
                      collectionName: collectionName,
                      remoteId: docChange.doc.id,
                      enterpriseId: enterpriseId,
                      moduleType: moduleType,
                    );

                    final localId = existingRecord?.localId ?? docChange.doc.id;

                    await driftService.records.upsert(
                      collectionName: collectionName,
                      localId: localId,
                      remoteId: docChange.doc.id,
                      enterpriseId: enterpriseId,
                      moduleType: moduleType,
                      dataJson: jsonEncode(
                        posData,
                        toEncodable: (nonEncodable) {
                          if (nonEncodable is Timestamp) {
                            return nonEncodable.toDate().toIso8601String();
                          }
                          return nonEncodable;
                        },
                      ),
                      localUpdatedAt: DateTime.now(),
                    );
                    break;
                  case DocumentChangeType.removed:
                    await driftService.records.deleteByRemoteId(
                      collectionName: collectionName,
                      remoteId: docChange.doc.id,
                      enterpriseId: enterpriseId,
                      moduleType: moduleType,
                    );
                    break;
                }
                _pulseSync();
              } catch (e) {
                AppLogger.warning('Error processing sub-tenant change: $e', name: 'admin.realtime.sync');
              }
            }
          },
          onError: (error, stackTrace) {
             AppLogger.warning('Listen failed for $subName in $enterpriseId: $error', name: 'admin.realtime.sync');
          },
        );
        subs.add(subscription);
      } catch (e) {
        AppLogger.warning('Error setting up $subName listener for $enterpriseId: $e', name: 'admin.realtime.sync');
      }
    }

    if (subs.isNotEmpty) {
      // Pour cet exemple, on stocke une seule subscription qui les annule toutes
      _pointOfSaleSubscriptions[enterpriseId] = StreamSubscriptionManager(subs);
      developer.log(
        'Started listening to sub-tenants for enterprise $enterpriseId',
        name: 'admin.realtime.sync',
      );
    }
  }
}

/// Simple helper to manage multiple subscriptions
class StreamSubscriptionManager implements StreamSubscription<QuerySnapshot> {
  final List<StreamSubscription> _subscriptions;
  StreamSubscriptionManager(this._subscriptions);

  @override
  Future<void> cancel() async {
    await Future.wait(_subscriptions.map((s) => s.cancel()));
  }

  @override
  void onData(void Function(QuerySnapshot data)? handleData) {}
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) {
    for (var s in _subscriptions) { s.pause(resumeSignal); }
  }
  @override
  void resume() {
    for (var s in _subscriptions) { s.resume(); }
  }
  @override
  bool get isPaused => _subscriptions.any((s) => s.isPaused);
  
  @override
  Future<E> asFuture<E>([E? futureValue]) => throw UnimplementedError();
}

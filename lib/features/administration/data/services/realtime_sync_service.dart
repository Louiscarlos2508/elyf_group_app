import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, QuerySnapshot, DocumentSnapshot, DocumentChange, DocumentChangeType, Timestamp, FirebaseException, GetOptions, Source, FieldPath;
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
  StreamSubscription? _usersSubscription;
  StreamSubscription? _enterprisesSubscription;
  StreamSubscription? _rolesSubscription;
  StreamSubscription? _enterpriseModuleUsersSubscription;
  StreamSubscription<DocumentSnapshot>? _specificUserSubscription;
  // Map pour stocker les subscriptions des points de vente par entreprise (utilisé pour les non-admins)
  final Map<String, StreamSubscription> _pointOfSaleSubscriptions = {};
  
  // Nouveaux écouteurs globaux pour les admins
  StreamSubscription<QuerySnapshot>? _pointsOfSaleGroupSubscription;
  StreamSubscription<QuerySnapshot>? _agencesGroupSubscription;

  // Nouveaux dictionnaires pour les souscriptions spécifiques par ID
  final Map<String, StreamSubscription> _specificEnterpriseSubscriptions = {};
  final Map<String, StreamSubscription> _specificSubTenantSubscriptions = {};

  // Cache des enterpriseIds connus pour détecter les changements
  Set<String> _knownEnterpriseIds = {};

  bool _isListening = false;
  bool _isStopping = false;

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

  Future<void> dispose() async {
    await stopRealtimeSync();
    if (!_syncStatusController.isClosed) {
      await _syncStatusController.close();
    }
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

  Future<User?> _getCurrentUserFromLocal() async {
    if (_currentUserId == null) return null;
    try {
      final record = await driftService.records.findByRemoteId(
        collectionName: _usersCollection,
        remoteId: _currentUserId!,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      if (record == null) return null;
      final userData = jsonDecode(record.dataJson) as Map<String, dynamic>;
      return User.fromMap(userData);
    } catch (e) {
      return null;
    }
  }

  String? _currentUserId;

  /// Arrête l'écoute en temps réel et libère les ressources.
  Future<void> stopRealtimeSync() async {
    if (_isStopping) return;
    _isStopping = true;
    
    final List<Future<void>> cancelFutures = [];
    
    if (_usersSubscription != null) cancelFutures.add(_usersSubscription!.cancel());
    if (_enterprisesSubscription != null) cancelFutures.add(_enterprisesSubscription!.cancel());
    if (_rolesSubscription != null) cancelFutures.add(_rolesSubscription!.cancel());
    if (_enterpriseModuleUsersSubscription != null) cancelFutures.add(_enterpriseModuleUsersSubscription!.cancel());
    if (_specificUserSubscription != null) cancelFutures.add(_specificUserSubscription!.cancel());
    if (_pointsOfSaleGroupSubscription != null) cancelFutures.add(_pointsOfSaleGroupSubscription!.cancel());
    if (_agencesGroupSubscription != null) cancelFutures.add(_agencesGroupSubscription!.cancel());
    
    for (final sub in _pointOfSaleSubscriptions.values) {
      cancelFutures.add(sub.cancel());
    }
    
    for (final sub in _specificEnterpriseSubscriptions.values) {
      cancelFutures.add(sub.cancel());
    }
    
    for (final sub in _specificSubTenantSubscriptions.values) {
      cancelFutures.add(sub.cancel());
    }
    
    await Future.wait(cancelFutures);

    _usersSubscription = null;
    _enterprisesSubscription = null;
    _rolesSubscription = null;
    _enterpriseModuleUsersSubscription = null;
    _specificUserSubscription = null;
    _pointsOfSaleGroupSubscription = null;
    _agencesGroupSubscription = null;

    _pointOfSaleSubscriptions.clear();
    _specificEnterpriseSubscriptions.clear();
    _specificSubTenantSubscriptions.clear();
    
    _isListening = false;
    _initialPullCompleted = false;
    _currentUserId = null;
    _knownEnterpriseIds.clear();
    _isStopping = false;
    
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
    if (_isListening && _currentUserId == userId && !_isStopping) {
      developer.log(
        'RealtimeSyncService already listening for user: $userId',
        name: 'admin.realtime.sync',
      );
      return;
    }

    if (_isStopping) {
      developer.log(
        'RealtimeSyncService: Cannot start while stopping. Waiting...',
        name: 'admin.realtime.sync',
      );
      // Wait a bit or let the next call handle it
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

  /// Listen to a specific sub-tenant document using direct path if possible, or collectionGroup as last resort
  void _listenToSpecificSubTenant(String collectionName, String uid, {String? parentId}) {
    if (_pointOfSaleSubscriptions.containsKey(uid)) return;

    Stream<DocumentSnapshot>? stream;

    // Use parentId if provided, otherwise try to detect it from UID pattern
    String? finalParentId = parentId;
    if (finalParentId == null || finalParentId.isEmpty) {
      final parts = uid.split('_');
      if (parts.length >= 3) {
        finalParentId = '${parts[1]}_${parts[2]}';
        developer.log('Detected parent $finalParentId from sub-tenant UID pattern: $uid', name: 'admin.realtime.sync');
      }
    }

    // Direct path is always preferred to avoid PERMISSION_DENIED on collectionGroup
    if (finalParentId != null && finalParentId.isNotEmpty) {
      stream = firestore
          .collection(_enterprisesCollection)
          .doc(finalParentId)
          .collection(collectionName)
          .doc(uid)
          .snapshots();
    } else {
      // Fallback to collectionGroup if parent is unknown (will likely fail for non-admins)
      developer.log('Warning: Listening to sub-tenant $uid without parent ID using collectionGroup fallback (will check permissions)', name: 'admin.realtime.sync');
      
      // Check if user is system admin before trying collectionGroup
      // We don't have direct access to 'isAdmin' here easily without a local lookup,
      // so we use a try-catch on the listener itself which is already there.
      
      _pointOfSaleSubscriptions[uid] = firestore
          .collectionGroup(collectionName)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
            for (final docChange in snapshot.docChanges) {
               _handleSubTenantDocChange(collectionName, docChange);
            }
          }, onError: (e) {
             if (_isStopping || !_isListening) return;
             if (e is FirebaseException && e.code == 'permission-denied') {
                developer.log('Permission denied for collectionGroup scan of $uid (expected for non-admins). Aborting fallback.', name: 'admin.realtime.sync');
             } else {
                AppLogger.warning('Listen failed for specific sub-tenant $uid fallback: $e');
             }
          });
      return;
    }

    _pointOfSaleSubscriptions[uid] = (stream as Stream<dynamic>).listen((docSnapshot) async {
       if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>?;
          if (data == null) return;
          final enterpriseData = Map<String, dynamic>.from(data);
          if (!enterpriseData.containsKey('id')) enterpriseData['id'] = docSnapshot.id;
          
          // Ensure parentEnterpriseId is set
          if (finalParentId != null && !enterpriseData.containsKey('parentEnterpriseId')) {
            enterpriseData['parentEnterpriseId'] = finalParentId;
          }
          
          await _saveEnterpriseToLocal(Enterprise.fromMap(enterpriseData));
          _pulseSync();
       }
    }, onError: (e) {
       if (_isStopping || !_isListening) return;
       if (e is FirebaseException && e.code == 'permission-denied') {
          developer.log('Permission denied for direct path to sub-tenant $uid ($finalParentId).', name: 'admin.realtime.sync');
       } else {
          AppLogger.warning('Direct path listen failed for sub-tenant $uid: $e');
       }
    });
  }

  void _handleSubTenantDocChange(String collectionName, DocumentChange docChange) async {
    try {
      final data = docChange.doc.data();
      if (data == null) return;

      final posData = Map<String, dynamic>.from(data as Map)
        ..['id'] = docChange.doc.id;

      // Determine parentId if missing
      String? parentId = posData['parentEnterpriseId'];
      if (parentId == null || parentId.isEmpty) {
        final parts = docChange.doc.id.split('_');
        if (parts.length >= 3) {
          parentId = '${parts[1]}_${parts[2]}';
          posData['parentEnterpriseId'] = parentId;
        }
      }

      if (parentId == null) return;

      final moduleType = collectionName == 'pointsOfSale' || collectionName == 'pointOfSale' ? 'gaz' : 'orange_money';
      final driftCollection = collectionName == 'pointsOfSale' || collectionName == 'pointOfSale' ? 'pointOfSale' : 'agences';

      final enterprise = Enterprise.fromMap(posData);

      switch (docChange.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _saveEnterpriseSubTenantToLocal(
            enterprise,
            parentId,
            driftCollection,
            moduleType,
          );
          break;
        case DocumentChangeType.removed:
          await driftService.records.deleteByRemoteId(
            collectionName: driftCollection,
            remoteId: docChange.doc.id,
            enterpriseId: parentId,
            moduleType: moduleType,
          );
          break;
      }
      _pulseSync();
    } catch (e) {
      AppLogger.warning('Error handling sub-tenant doc change: $e', name: 'admin.realtime.sync');
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
      final currentUser = await _getCurrentUserFromLocal();
      final isAdmin = currentUser?.isAdmin ?? false;

      // Un admin peut écouter TOUS les utilisateurs
      if (isAdmin) {
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
                if (_isStopping || !_isListening) return;
                if (error is FirebaseException && error.code == 'permission-denied') {
                  AppLogger.info(
                    'Note: Switching to filtered users sync (global access restricted).',
                    name: 'admin.realtime.sync',
                  );
                  _listenToSpecificUser(_currentUserId!);
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
      } else if (_currentUserId != null) {
        // Non-admin : n'écouter que soi-même
        _listenToSpecificUser(_currentUserId!);
      }
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
      final currentUser = await _getCurrentUserFromLocal();
      final isAdmin = currentUser?.isAdmin ?? false;

      if (isAdmin) {
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
                if (_isStopping || !_isListening) return;
                if (error is FirebaseException && error.code == 'permission-denied') {
                  AppLogger.info(
                    'Note: Switching to filtered enterprises sync (global access restricted).',
                    name: 'admin.realtime.sync',
                  );
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
      } else {
        _listenToAssignedEnterprises();
      }
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
      final currentUser = await _getCurrentUserFromLocal();
      final isAdmin = currentUser?.isAdmin ?? false;

      if (isAdmin) {
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
                if (_isStopping || !_isListening) return;
                if (error is FirebaseException && error.code == 'permission-denied') {
                  AppLogger.info(
                    'Note: Switching to filtered roles sync (global access restricted).',
                    name: 'admin.realtime.sync',
                  );
                  _listenToAssignedRoles();
                } else {
                  final appException = ErrorHandler.instance.handleError(error, stackTrace);
                  AppLogger.error(
                    'Error in roles realtime stream: ${appException.message}',
                    name: 'admin.realtime.sync',
                    error: error,
                    stackTrace: stackTrace,
                  );
                }
              },
            );
      } else {
        _listenToAssignedRoles();
      }
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
                // Trigger specific enterprise listener for this assignment
                _listenToAssignedEnterprise(assignment.enterpriseId, assignment.parentEnterpriseId, assignment.moduleId);
                
                developer.log(
                  'EnterpriseModuleUser ${docChange.type.name} in realtime: ${assignment.documentId}',
                  name: 'admin.realtime.sync',
                );
                break;
              case DocumentChangeType.removed:
                await _deleteEnterpriseModuleUserFromLocal(
                  assignment.documentId,
                );
                // We don't necessarily cancel the enterprise listener here 
                // as the user might have other assignments to the same enterprise
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
      final currentUser = await _getCurrentUserFromLocal();
      final isAdmin = currentUser?.isAdmin ?? false;

      // Un admin peut écouter TOUS les documents
      if (isAdmin) {
        _enterpriseModuleUsersSubscription = firestore
            .collection(_enterpriseModuleUsersCollection)
            .snapshots()
            .listen(
              handleSnapshot,
              onError: (error, stackTrace) {
                if (_isStopping || !_isListening) return;
                // Vérifier si c'est une erreur de permission
                if (error is FirebaseException &&
                    error.code == 'permission-denied') {
                  
                  AppLogger.info(
                    'Note: Switching to filtered assignments sync (global access restricted).',
                    name: 'admin.realtime.sync',
                  );
                  // Tentative 2: Fallback sur l'utilisateur courant si disponible
                  if (_currentUserId != null) {
                    _retryListenToUserEnterpriseModuleUsers(handleSnapshot);
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
      } else if (_currentUserId != null) {
        // Non-admin : n'écouter que ses propres assignations
        _retryListenToUserEnterpriseModuleUsers(handleSnapshot);
      }
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

  /// Helper pour écouter les assignations de l'utilisateur ET de ses entreprises
  Future<void> _retryListenToUserEnterpriseModuleUsers(
    Function(QuerySnapshot) onSnapshot,
  ) async {
    if (_isStopping) return;
    if (_currentUserId == null) return;

    // Annuler la souscription précédente qui a échoué
    _enterpriseModuleUsersSubscription?.cancel();

    developer.log(
      'Starting filtered sync for user: $_currentUserId and their enterprises',
      name: 'admin.realtime.sync',
    );

    try {
      // 1. Récupérer les IDs d'entreprises de l'utilisateur depuis le local
      final userRecord = await driftService.records.findByRemoteId(
        collectionName: _usersCollection,
        remoteId: _currentUserId!,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final Set<String> targetEnterpriseIds = {};
      if (userRecord != null) {
        try {
          final userData = jsonDecode(userRecord.dataJson);
          final ids = (userData['enterpriseIds'] as List?)?.map((e) => e.toString()).toList();
          if (ids != null) {
            targetEnterpriseIds.addAll(ids);
          }
        } catch (e) {
          developer.log('Error parsing user enterpriseIds for sync: $e', name: 'admin.realtime.sync');
        }
      }

      // 1.5 Découverte locale des sous-tenants (POS/Agences) pour les enterprises déjà connues
      // On cherche localement les entités dont le parent est dans targetEnterpriseIds
      try {
        final allEnterprises = await driftService.records.listForCollection(collectionName: 'enterprises');
        final posEnterprises = await driftService.records.listForCollection(collectionName: 'pointOfSale');
        final agencesEnterprises = await driftService.records.listForCollection(collectionName: 'agences');
        
        final Set<String> discoveredIds = {};
        for (final record in [...allEnterprises, ...posEnterprises, ...agencesEnterprises]) {
          try {
            final data = jsonDecode(record.dataJson);
            final parentId = data['parentEnterpriseId'] as String?;
            if (parentId != null && targetEnterpriseIds.contains(parentId)) {
              discoveredIds.add(record.remoteId ?? record.localId);
            }
          } catch (_) {}
        }
        targetEnterpriseIds.addAll(discoveredIds);
      } catch (e) {
        developer.log('Error discovering child enterprises locally: $e', name: 'admin.realtime.sync');
      }

      // 2. Créer les streams
      final List<Stream<QuerySnapshot>> streams = [];
      
      // Toujours écouter ses propres assignations (sécurité/fallback)
      streams.add(firestore
          .collection(_enterpriseModuleUsersCollection)
          .where('userId', isEqualTo: _currentUserId)
          .snapshots());

      // Écouter toutes les assignations des entreprises auxquelles on appartient (+ sous-tenants découverts)
      if (targetEnterpriseIds.isNotEmpty) {
        final idsList = targetEnterpriseIds.toList();
        // Chunk par 30 pour respecter les limites Firestore
        for (var i = 0; i < idsList.length; i += 30) {
          final chunk = idsList.sublist(i, i + 30 > idsList.length ? idsList.length : i + 30);
          streams.add(firestore
              .collection(_enterpriseModuleUsersCollection)
              .where('enterpriseId', whereIn: chunk)
              .snapshots());
        }
      }

      // Combiner tous les streams et traiter les snapshots
      _enterpriseModuleUsersSubscription = Rx.merge(streams).listen(
            (snapshot) => onSnapshot(snapshot),
            onError: (error, stackTrace) {
              final appException =
                  ErrorHandler.instance.handleError(error, stackTrace);
              AppLogger.error(
                'Error in enterprise_module_users filtered stream: ${appException.message}',
                name: 'admin.realtime.sync',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error setting up filtered enterprise_module_users listener',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// New consolidated method to listen to an enterprise (root or sub-tenant)
  void _listenToAssignedEnterprise(String enterpriseId, String? parentId, String? moduleId) {
    if (parentId == null || parentId.isEmpty) {
        // Root enterprise
        _listenToSpecificEnterprise(enterpriseId);
    } else {
        // Sub-tenant
        String collectionName = 'pointsOfSale';
        if (moduleId == 'orange_money') {
            collectionName = 'agences';
        } else if (moduleId == 'gaz') {
            collectionName = 'pointsOfSale';
        }
        _listenToSpecificSubTenant(collectionName, enterpriseId, parentId: parentId);
    }
  }

  void _listenToSpecificEnterprise(String enterpriseId) {
    if (_specificEnterpriseSubscriptions.containsKey(enterpriseId)) return;

    _specificEnterpriseSubscriptions[enterpriseId] = firestore
        .collection(_enterprisesCollection)
        .doc(enterpriseId)
        .snapshots()
        .listen((doc) async {
            if (doc.exists) {
                final data = doc.data()!;
                final enterpriseData = Map<String, dynamic>.from(data as Map);
                if (!enterpriseData.containsKey('id')) enterpriseData['id'] = doc.id;
                await _saveEnterpriseToLocal(Enterprise.fromMap(enterpriseData));
                _pulseSync();
            }
        }, onError: (e) {
            // Permission errors are expected for some users
        });
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
        
        // Détecter un changement d'enterpriseIds pour rafraîchir les écouteurs filtrés
        final newEnterpriseIds = Set<String>.from(user.enterpriseIds);
        final hasChanged = _knownEnterpriseIds.length != newEnterpriseIds.length ||
            !_knownEnterpriseIds.every(newEnterpriseIds.contains);
            
        await _saveUserToLocal(user);
        
        if (hasChanged && _isListening && !_isStopping) {
          developer.log(
            'User enterpriseIds changed (${_knownEnterpriseIds.length} -> ${newEnterpriseIds.length}). Refreshing filtered listeners...',
            name: 'admin.realtime.sync',
          );
          _knownEnterpriseIds = newEnterpriseIds;
          
          // Rafraîchir les écouteurs qui dépendent des permissions utilisateur
          // Utiliser des délais courts pour éviter les rafales si plusieurs changements arrivent
          _listenToAssignedUsers();
          _listenToAssignedEnterprises();
          _listenToEnterpriseModuleUsers();
        } else {
          _knownEnterpriseIds = newEnterpriseIds;
        }
        
        _pulseSync();
      } catch (e) {
        AppLogger.warning('Error in specific user listener: $e', name: 'admin.realtime.sync');
      }
    }, onError: (error, _) {
       if (_isStopping || !_isListening) return;
       AppLogger.warning('Listen failed for specific user: $error', name: 'admin.realtime.sync');
    });
  }

  /// Listen to users assigned to the same enterprises as the current user
  Future<void> _listenToAssignedUsers() async {
    if (_isStopping) return;
    if (_currentUserId == null) return;
    
    // Always listen to current user profile
    _listenToSpecificUser(_currentUserId!);

    try {
      // 1. Get enterprise IDs from local user record
      final userRecord = await driftService.records.findByRemoteId(
        collectionName: _usersCollection,
        remoteId: _currentUserId!,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final Set<String> targetEnterpriseIds = {};
      if (userRecord != null) {
        try {
          final userData = jsonDecode(userRecord.dataJson);
          final ids = (userData['enterpriseIds'] as List?)?.map((e) => e.toString()).toList();
          if (ids != null) {
            targetEnterpriseIds.addAll(ids);
          }
        } catch (_) {}
      }

      if (targetEnterpriseIds.isEmpty) return;

      // 2. Setup filtered listeners for users in these enterprises
      final List<Stream<QuerySnapshot>> streams = [];
      final idsList = targetEnterpriseIds.toList();
      
      // Chunk by 10 for 'array-contains-any'
      for (var i = 0; i < idsList.length; i += 10) {
        final chunk = idsList.sublist(i, i + 10 > idsList.length ? idsList.length : i + 10);
        streams.add(firestore
            .collection(_usersCollection)
            .where('enterpriseIds', arrayContainsAny: chunk)
            .snapshots());
      }

      _usersSubscription?.cancel();
      _usersSubscription = Rx.merge(streams).listen((snapshot) async {
        for (final docChange in snapshot.docChanges) {
          try {
            final data = docChange.doc.data();
            if (data == null) continue;
            final userData = Map<String, dynamic>.from(data as Map);
            if (!userData.containsKey('id')) userData['id'] = docChange.doc.id;
            final user = User.fromMap(userData);

            switch (docChange.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _saveUserToLocal(user);
                break;
              case DocumentChangeType.removed:
                await _deleteUserFromLocal(user.id);
                break;
            }
            _pulseSync();
          } catch (e) {
            AppLogger.warning('Error processing user change in assigned users sync: $e', name: 'admin.realtime.sync');
          }
        }
      }, onError: (error, _) {
        AppLogger.warning('Assigned users listen failed: $error', name: 'admin.realtime.sync');
      });
    } catch (e) {
      AppLogger.warning('Error setting up assigned users listener: $e', name: 'admin.realtime.sync');
    }
  }

  Future<void> _listenToAssignedEnterprises() async {
    if (_isStopping) return;
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
      
      // AJOUT : Inclure les entreprises rattachées directement au profil utilisateur
      final localUser = await driftService.records.findByRemoteId(
        collectionName: _usersCollection,
        remoteId: _currentUserId ?? '',
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      
      if (localUser != null) {
        final userData = jsonDecode(localUser.dataJson) as Map<String, dynamic>;
        final List<dynamic>? directIds = userData['enterpriseIds'] as List<dynamic>?;
        if (directIds != null) {
          for (final id in directIds) {
            enterpriseIds.add(id.toString());
          }
        }
      }
      
      if (enterpriseIds.isEmpty) return;

      developer.log('Listening to ${enterpriseIds.length} assigned/direct enterprises in realtime...', name: 'admin.realtime.sync');

      // Pour éviter de multiplier les subscriptions, on utilise Rx.merge
      final List<Stream<DocumentSnapshot>> streams = [];

      for (var id in enterpriseIds) {
        final idStr = id.toString();
        streams.add(firestore.collection(_enterprisesCollection).doc(idStr).snapshots());
      }

      _enterprisesSubscription = Rx.merge(streams).listen((doc) async {
        if (doc.exists) {
          final data = doc.data()!;
          final enterpriseData = Map<String, dynamic>.from(data as Map);
          if (!enterpriseData.containsKey('id')) enterpriseData['id'] = doc.id;
          await _saveEnterpriseToLocal(Enterprise.fromMap(enterpriseData));
          _pulseSync();
        } else {
          // If not in root, it might be a sub-tenant (POS/Agence)
          // Try to detect parent from ID pattern first
          final idStr = doc.id;
          String? parentId;
          String? subCollName;
          String? collectionKey;

          // pattern matching approach
          if (idStr.startsWith('pos_')) {
            final parts = idStr.split('_');
            if (parts.length >= 3) {
              parentId = '${parts[1]}_${parts[2]}';
              subCollName = 'pointsOfSale';
              collectionKey = 'pointOfSale';
            }
          } else if (idStr.startsWith('agence_') || idStr.startsWith('mm_')) {
            final parts = idStr.split('_');
            if (parts.length >= 3) {
              parentId = '${parts[1]}_${parts[2]}';
              subCollName = 'agences';
              collectionKey = 'agences';
            }
          }

          // fallback to local lookup if pattern failed
          if (parentId == null) {
            final localEnt = await driftService.records.findInCollectionByRemoteId(
              collectionName: 'pointOfSale',
              remoteId: idStr,
            ) ?? await driftService.records.findInCollectionByRemoteId(
              collectionName: 'agences',
              remoteId: idStr,
            );

            if (localEnt != null) {
              final entData = jsonDecode(localEnt.dataJson) as Map<String, dynamic>;
              parentId = entData['parentEnterpriseId'] as String?;
              final typeStr = entData['type'] as String? ?? 'gaz_pos';
              if (typeStr.contains('gaz')) {
                 subCollName = 'pointsOfSale';
                 collectionKey = 'pointOfSale';
              } else {
                 subCollName = 'agences';
                 collectionKey = 'agences';
              }
            }
          }

          if (parentId != null && subCollName != null) {
            final finalParentId = parentId;
            final finalCollectionKey = collectionKey!;
            _listenToSpecificSubTenantQuery(finalCollectionKey, idStr, parentId: finalParentId);
          }
        }
      }, onError: (error, _) {
        AppLogger.warning('Assigned enterprises listen failed: $error', name: 'admin.realtime.sync');
      });
    } catch (e) {
      AppLogger.warning('Error setting up assigned enterprises listener: $e', name: 'admin.realtime.sync');
    }
  }

  /// Listens to a specific sub-tenant (e.g., Point of Sale or Agence)
  /// This is typically called when an enterprise document is not found in the main collection,
  /// suggesting it might be a sub-tenant.
  void _listenToSpecificSubTenantQuery(String collectionKey, String enterpriseId, {required String parentId}) {
    if (_specificSubTenantSubscriptions.containsKey(enterpriseId)) return;

    final subCollName = collectionKey == 'pointOfSale' ? 'pointsOfSale' : 'agences';
    final query = firestore
        .collection(_enterprisesCollection)
        .doc(parentId)
        .collection(subCollName)
        .where(FieldPath.documentId, isEqualTo: enterpriseId); // Filter for the specific sub-tenant

    _specificSubTenantSubscriptions[enterpriseId] = query
        .snapshots()
        .listen((querySnapshot) async {
      for (final docChange in querySnapshot.docChanges) {
        if (docChange.doc.exists) {
          final data = docChange.doc.data();
          if (data == null) continue;
          
          final posData = Map<String, dynamic>.from(data as Map);
          if (!posData.containsKey('id')) posData['id'] = docChange.doc.id;

          String? finalParentId = posData['parentEnterpriseId'];
          if (finalParentId == null || finalParentId.isEmpty) {
             final parts = docChange.doc.id.split('_');
             if (parts.length >= 3) {
                 finalParentId = '${parts[1]}_${parts[2]}';
                 posData['parentEnterpriseId'] = finalParentId;
             }
          }

          if (finalParentId != null) {
            final enterprise = Enterprise.fromMap(posData);
            await _saveEnterpriseToLocal(enterprise);
            _pulseSync();
          }
        } else if (docChange.type == DocumentChangeType.removed) {
          // If a sub-tenant document is removed, delete it locally
          await _deleteEnterpriseFromLocal(docChange.doc.id);
          _pulseSync();
        }
      }
    }, onError: (error, _) {
      // Ignore permission denied here as it's a fallback mechanism
      AppLogger.warning('Error in specific enterprise query: $error', name: 'admin.realtime.sync');
    });
  }


  Future<void> _listenToAssignedRoles() async {
    if (_isStopping) return;
    if (_currentUserId == null) return;
    _rolesSubscription?.cancel();

    try {
      // 1. Récupérer toutes les assignations locales pour trouver les roleIds nécessaires
      final assignments = await driftService.records.listForEnterprise(
        collectionName: _enterpriseModuleUsersCollection,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final Set<String> roleIds = {};
      for (final record in assignments) {
        try {
          final data = jsonDecode(record.dataJson);
          final roles = (data['roleIds'] as List?)?.map((r) => r.toString()).toList();
          if (roles != null) {
            roleIds.addAll(roles);
          }
        } catch (_) {}
      }

      // Ajouter les rôles système par défaut s'ils ne sont pas déjà inclus
      roleIds.addAll(['admin', 'admin_gaz', 'admin_eau_minerale', 'admin_orange_money', 'admin_immobilier', 'admin_boutique']);

      if (roleIds.isEmpty) return;

      developer.log('Listening to ${roleIds.length} assigned roles in realtime...', name: 'admin.realtime.sync');

      final List<Stream<DocumentSnapshot>> streams = [];
      for (final id in roleIds) {
        streams.add(firestore.collection(_rolesCollection).doc(id).snapshots());
      }

      _rolesSubscription = Rx.merge(streams).listen((doc) async {
        if (doc.exists) {
          final data = doc.data()!;
          final roleData = Map<String, dynamic>.from(data as Map);
          if (!roleData.containsKey('id')) roleData['id'] = doc.id;
          
          final firestoreUpdatedAt = _getTimestampFromData(roleData);
          final role = UserRole.fromMap(roleData);

          if (await _shouldUpdateRoleFromFirestore(
            roleId: role.id,
            firestoreUpdatedAt: firestoreUpdatedAt,
          )) {
            await _saveRoleToLocal(
              role, 
              firestoreUpdatedAt: firestoreUpdatedAt,
            );
            _pulseSync();
          }
        }
      }, onError: (error, _) {
        AppLogger.warning('Assigned roles listen failed: $error', name: 'admin.realtime.sync');
      });
    } catch (e) {
      AppLogger.warning('Error setting up assigned roles listener: $e', name: 'admin.realtime.sync');
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
      // Déterminer la collection correcte (identique à FirestoreSyncService)
      String targetCollection = _enterprisesCollection;
      if (enterprise.type.isGas && !enterprise.type.isMain) {
        targetCollection = 'pointOfSale';
      } else if (enterprise.type.isMobileMoney && !enterprise.type.isMain) {
        targetCollection = 'agences';
      }

      final parentId = enterprise.parentEnterpriseId ?? 'global';
      final moduleType = (!enterprise.type.isMain) 
          ? enterprise.type.module.id 
          : 'administration';

      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: targetCollection,
        remoteId: enterprise.id,
        enterpriseId: parentId,
        moduleType: moduleType,
      );

      final localId = existingRecord?.localId ?? enterprise.id;
      final map = enterprise.toMap();
      
      await driftService.records.upsert(
        collectionName: targetCollection,
        localId: localId,
        remoteId: enterprise.id,
        enterpriseId: parentId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Si c'était un sous-tenant indûment enregistré dans 'enterprises', le supprimer pour éviter les doublons
      if (targetCollection != _enterprisesCollection) {
        await driftService.records.deleteByRemoteId(
          collectionName: _enterprisesCollection,
          remoteId: enterprise.id,
          enterpriseId: 'global',
          moduleType: 'administration',
        );
      }
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
      final currentUser = await _getCurrentUserFromLocal();
      final isAdmin = currentUser?.isAdmin ?? false;

      if (isAdmin) {
        // Mode itératif (Admin uniquement car nécessite de lister toutes les entreprises)
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
      } else {
        // Non-admin : passer directement au fallback des entreprises assignées
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Non-admin users cannot list all enterprises.',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        developer.log(
          'Permission denied or non-admin reading ALL enterprises for sub-tenants. Falling back to assigned enterprises.',
          name: 'admin.realtime.sync',
        );
        if (_currentUserId == null) return;
        try {
          // Utiliser les entreprises assignées chargées en local ou via Firestore
          final userDoc = await firestore.collection(_usersCollection).doc(_currentUserId).get(const GetOptions(source: Source.server));
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
    if (_specificSubTenantSubscriptions.containsKey(enterpriseId) || _isStopping) {
      return;
    }
    
    final List<StreamSubscription> subs = [];
    
    // Vérifier si l'utilisateur a un accès "Parent" (admin système ou listé dans enterpriseIds)
    // Sinon, on ne peut pas écouter la collection entière (on écoutera les docs individuels via _listenToAssignedEnterprises)
    bool hasParentAccess = false;
    final localUser = await driftService.records.findByRemoteId(
      collectionName: _usersCollection,
      remoteId: _currentUserId ?? '',
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    if (localUser != null) {
      final userData = jsonDecode(localUser.dataJson) as Map<String, dynamic>;
      final bool isAdmin = userData['isAdmin'] == true;
      final List<dynamic>? directIds = userData['enterpriseIds'] as List<dynamic>?;
      hasParentAccess = isAdmin || (directIds?.contains(enterpriseId) ?? false);
    }

    if (!hasParentAccess) {
      developer.log(
        'User does not have parent access to $enterpriseId. Skipping whole-collection listen for sub-tenants.',
        name: 'admin.realtime.sync',
      );
      return;
    }
    
    for (final subName in ['pointsOfSale', 'agences']) {
      final moduleType = subName == 'pointsOfSale' ? 'gaz' : 'orange_money';
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
                        final enterprise = Enterprise.fromMap(posData);
                        await _saveEnterpriseSubTenantToLocal(
                          enterprise,
                          enterpriseId,
                          collectionName,
                          moduleType,
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
                 if (_isStopping || !_isListening) return;
                 AppLogger.warning('Listen failed for $subName in $enterpriseId: $error', name: 'admin.realtime.sync');
              },
            );
            subs.add(subscription);
          } catch (e) {
            AppLogger.warning('Error setting up $subName listener for $enterpriseId: $e', name: 'admin.realtime.sync');
          }
        }

        if (subs.isNotEmpty) {
          _specificSubTenantSubscriptions[enterpriseId] = StreamSubscriptionGroup(subs);
          developer.log(
            'Started listening to sub-tenants for enterprise $enterpriseId',
            name: 'admin.realtime.sync',
          );
        }
      }
}

/// Helper to manage stream subscriptions
class StreamSubscriptionGroup implements StreamSubscription<dynamic> {
  final List<StreamSubscription> _subscriptions;
  StreamSubscriptionGroup(this._subscriptions);

  @override
  Future<void> cancel() async {
    await Future.wait(_subscriptions.map((s) => s.cancel()));
  }

  @override
  void onData(void Function(dynamic data)? handleData) {}

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

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, QuerySnapshot, DocumentChangeType, Timestamp, FirebaseException;

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
  // Map pour stocker les subscriptions des points de vente par entreprise
  final Map<String, StreamSubscription<QuerySnapshot>> _pointOfSaleSubscriptions = {};

  bool _isListening = false;

  /// Indique si le service écoute actuellement les changements.
  bool get isListening => _isListening;
  bool _initialPullCompleted = false;
  void dispose() {
    _usersSubscription?.cancel();
    _enterprisesSubscription?.cancel();
    _rolesSubscription?.cancel();
    _enterpriseModuleUsersSubscription?.cancel();
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
    for (final sub in _pointOfSaleSubscriptions.values) {
      sub.cancel();
    }
    _pointOfSaleSubscriptions.clear();
    
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
    _currentUserId = userId;
    
    if (_isListening) {
      developer.log(
        'RealtimeSyncService already listening',
        name: 'admin.realtime.sync',
      );
      return;
    }

    _setSyncing(true);

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
      await _listenToPointsOfSale();

      _isListening = true;
      _setSyncing(false);
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
    }
  }

  /// Pull initial depuis Firestore (One-time fetch).
  Future<void> _pullInitialDataFromFirestore() async {
    try {
      if (_initialPullCompleted) return;

      // Utiliser le service de synchro existant qui gère déjà bien le pull initial
      await firestoreSync.pullInitialData();
      
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
              final appException = ErrorHandler.instance.handleError(error, stackTrace);
              AppLogger.error(
                'Error in users realtime stream: ${appException.message}',
                name: 'admin.realtime.sync',
                error: error,
                stackTrace: stackTrace,
              );
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
                      await _listenToPointsOfSaleForEnterprise(enterprise.id);
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
              final appException = ErrorHandler.instance.handleError(error, stackTrace);
              AppLogger.error(
                'Error in enterprises realtime stream: ${appException.message}',
                name: 'admin.realtime.sync',
                error: error,
                stackTrace: stackTrace,
              );
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
      
      // Utiliser le timestamp Firestore si fourni, sinon utiliser maintenant
      // Cela permet de préserver l'ordre chronologique des modifications
      final localUpdatedAt = firestoreUpdatedAt ?? DateTime.now();
      
      await driftService.records.upsert(
        collectionName: _rolesCollection,
        localId: role.id,
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

  /// Écoute les changements dans les collections pointsOfSale de toutes les entreprises.
  ///
  /// Pour chaque entreprise, écoute les changements dans sa sous-collection pointsOfSale.
  Future<void> _listenToPointsOfSale() async {
    try {
      // Récupérer toutes les entreprises pour écouter leurs points de vente
      final enterprisesSnapshot = await firestore
          .collection(_enterprisesCollection)
          .get();
      
      developer.log(
        'Setting up realtime listeners for points of sale in ${enterprisesSnapshot.docs.length} enterprises',
        name: 'admin.realtime.sync',
      );
      
      for (final enterpriseDoc in enterprisesSnapshot.docs) {
        final enterpriseId = enterpriseDoc.id;
        await _listenToPointsOfSaleForEnterprise(enterpriseId);
      }
      
      // Écouter aussi les nouvelles entreprises pour démarrer l'écoute de leurs points de vente
      // (cette logique est déjà gérée dans _listenToEnterprises)
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up points of sale realtime listeners: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Écoute les changements dans la collection pointsOfSale d'une entreprise spécifique.
  Future<void> _listenToPointsOfSaleForEnterprise(String enterpriseId) async {
    // Ne pas créer de doublon si on écoute déjà
    if (_pointOfSaleSubscriptions.containsKey(enterpriseId)) {
      return;
    }
    
    try {
      final posCollection = firestore
          .collection(_enterprisesCollection)
          .doc(enterpriseId)
          .collection('pointofsale');
      
      final subscription = posCollection.snapshots().listen(
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
                  // Sauvegarder localement
                  await driftService.records.upsert(
                    collectionName: 'pointOfSale',
                    localId: docChange.doc.id,
                    remoteId: docChange.doc.id,
                    enterpriseId: enterpriseId,
                    moduleType: 'gaz',
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
                  developer.log(
                    'Point of sale ${docChange.type.name} in realtime: ${docChange.doc.id} for enterprise $enterpriseId',
                    name: 'admin.realtime.sync',
                  );
                  break;
                case DocumentChangeType.removed:
                  await driftService.records.deleteByLocalId(
                    collectionName: 'pointOfSale',
                    localId: docChange.doc.id,
                    enterpriseId: enterpriseId,
                    moduleType: 'gaz',
                  );
                  developer.log(
                    'Point of sale removed in realtime: ${docChange.doc.id} for enterprise $enterpriseId',
                    name: 'admin.realtime.sync',
                  );
                  break;
              }
              _pulseSync();
            } catch (e, stackTrace) {
              final appException = ErrorHandler.instance.handleError(e, stackTrace);
              AppLogger.warning(
                'Error processing point of sale change in realtime sync: ${appException.message}',
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
            'Error in points of sale realtime stream for enterprise $enterpriseId: ${appException.message}',
            name: 'admin.realtime.sync',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      
      _pointOfSaleSubscriptions[enterpriseId] = subscription;
      developer.log(
        'Started listening to points of sale for enterprise $enterpriseId',
        name: 'admin.realtime.sync',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error setting up points of sale realtime listener for enterprise $enterpriseId: ${appException.message}',
        name: 'admin.realtime.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

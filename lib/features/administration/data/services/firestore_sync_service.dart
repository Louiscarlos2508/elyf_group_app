import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, QuerySnapshot, DocumentSnapshot, DocumentChangeType, Timestamp, FirebaseException, FieldPath, SetOptions, FieldValue, Query;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rxdart/rxdart.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
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
  FirestoreSyncService({required this.driftService, required this.firestore});

  final DriftService driftService;
  final FirebaseFirestore firestore;
  String? _currentUserId;

  // Collection paths
  static const String _usersCollection = 'users';
  static const String _enterprisesCollection = 'enterprises';
  static const String _rolesCollection = 'roles';
  static const String _enterpriseModuleUsersCollection =
      'enterprise_module_users';
  static const String _auditLogsCollection = 'audit_logs';

  /// Pulls all initial data from Firestore to local Drift database.
  ///
  /// This fetches Users, Enterprises, Roles, and EnterpriseModuleUsers.
  /// If [userId] is provided, only fetches assignments for that user.

  Future<void> pullInitialData({String? userId, List<String>? allowedEnterpriseIds}) async {
    // Si on est sur le Web, l'administration utilise directement Firestore (online-only)
    // On ne veut pas essayer d'écrire dans Drift (car sql.js n'est pas chargé)
    if (kIsWeb) {
      developer.log(
        'FirestoreSyncService: Skipping initial pull on Web (using direct Firestore)',
        name: 'admin.firestore.sync',
      );
      return;
    }
    _currentUserId = userId;

    // Nettoyage initial des doublons : si une entité est dans agences/pointOfSale, 
    // elle ne doit plus être dans 'enterprises' racine pour éviter les doublons d'affichage.
    try {
      for (final subCollection in ['pointOfSale', 'agences']) {
        final subTenantRecords = await driftService.records.listForCollection(
          collectionName: subCollection,
        );
        for (final record in subTenantRecords) {
          final idToRemove = record.remoteId ?? record.localId;
          await driftService.records.deleteByRemoteId(
            collectionName: _enterprisesCollection,
            remoteId: idToRemove,
            enterpriseId: 'global',
            moduleType: 'administration',
          );
        }
      }
    } catch (e) {
      developer.log('Cleanup of redundant enterprises failed: $e', name: 'admin.firestore.sync');
    }

    try {
      developer.log(
        'Starting initial pull of all collections...',
        name: 'admin.firestore.sync',
      );

      // 1. D'abord, récupérer l'utilisateur courant pour obtenir ses enterpriseIds
      User? currentUser;
      if (userId != null) {
        currentUser = await _pullAndSaveSpecificUser(userId);
      }

      final Set<String> effectiveAllowedEnterpriseIds = {
        ...?allowedEnterpriseIds,
        ...?currentUser?.enterpriseIds,
      };
      final bool isAdmin = (currentUser != null && currentUser.username == 'admin');

      // 2. Découvrir tous les sous-tenants (POS/Agences) pour les enterprises autorisées
      // Cela est crucial car les assignments peuvent être faits sur des sous-entités
      // qui ne sont pas explicitement dans currentUser.enterpriseIds
      if (effectiveAllowedEnterpriseIds.isNotEmpty) {
        developer.log('Discovering sub-tenants for ${effectiveAllowedEnterpriseIds.length} enterprises...', name: 'admin.firestore.sync');
        for (final parentId in effectiveAllowedEnterpriseIds.toList()) {
          // Chercher dans les sous-collections de chaque entreprise parente
          for (final subCollection in ['pointsOfSale', 'agences']) {
            try {
              final subSnapshot = await firestore
                  .collection(_enterprisesCollection)
                  .doc(parentId)
                  .collection(subCollection)
                  .get();
              
              for (final doc in subSnapshot.docs) {
                if (!effectiveAllowedEnterpriseIds.contains(doc.id)) {
                  effectiveAllowedEnterpriseIds.add(doc.id);
                  // Sauvegarder l'entité sous-tenant immédiatement car on en aura besoin pour le mapping UI
                  final data = Map<String, dynamic>.from(doc.data());
                  final subTenant = Enterprise.fromMap({
                    ...data, 
                    'id': doc.id, 
                    'parentEnterpriseId': parentId,
                  });
                  await _saveSubTenantToDrift(subTenant, parentId);
                }
              }
            } catch (e) {
              // Ignorer si pas d'accès ou erreur
              AppLogger.debug('Could not fetch sub-collection $subCollection for $parentId: $e');
            }
          }
        }
      }

      // 3. Fetch EnterpriseModuleUsers for ALL discovered enterprises
      // On ne filtre plus par userId seulement, car on veut voir TOUTES les assignations
      // des entreprises qu'on gère (pour voir les agents assignés).
      List<EnterpriseModuleUser> emus = [];
      if (isAdmin) {
        emus = await pullEnterpriseModuleUsersFromFirestore();
      } else if (effectiveAllowedEnterpriseIds.isNotEmpty) {
        // Fetch assignments for each enterprise the user has access to
        final List<String> idList = effectiveAllowedEnterpriseIds.toList();
        // Firestore 'whereIn' est limité à 30 (ou 10 selon les cas), on fait par chunks
        for (var i = 0; i < idList.length; i += 10) {
          final chunk = idList.sublist(i, i + 10 > idList.length ? idList.length : i + 10);
          try {
            final snapshot = await firestore
                .collection(_enterpriseModuleUsersCollection)
                .where('enterpriseId', whereIn: chunk)
                .get();
            
            emus.addAll(snapshot.docs.map((doc) => 
              EnterpriseModuleUser.fromMap(doc.data() as Map<String, dynamic>)));
          } catch (e) {
            AppLogger.warning('Error pulling emus for chunk: $e');
          }
        }
        
        // Ajouter aussi les assignations directes de l'utilisateur (même si l'entreprise n'est pas "gérée")
        if (userId != null) {
          final userEmus = await pullEnterpriseModuleUsersFromFirestore(userId: userId);
          for (final emu in userEmus) {
            if (!emus.any((e) => e.documentId == emu.documentId)) {
              emus.add(emu);
            }
          }
        }
      }

      for (final emu in emus) {
        await _saveEnterpriseModuleUserToDrift(emu);
      }

      // 4. Parallel fetch for other collections using filters
      await Future.wait([
        if (isAdmin || userId == null) _pullAndSaveUsers() else Future.value(),
        _pullAndSaveEnterprises(allowedEnterpriseIds: isAdmin ? null : effectiveAllowedEnterpriseIds.toList()),
        _pullAndSaveRoles(),
      ]);

      developer.log(
        'Initial pull completed successfully. Total accessible enterprises (incl. sub-tenants): ${effectiveAllowedEnterpriseIds.length}',
        name: 'admin.firestore.sync',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error pulling initial data: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Propagate error
      rethrow;
    }
  }

  Future<void> _pullAndSaveUsers() async {
    try {
      final users = await pullUsersFromFirestore();
      for (final user in users) {
        await _saveUserToDrift(user);
      }
    } catch (e) {
      AppLogger.warning('Failed to pull all users (likely permission denied)', name: 'admin.firestore.sync');
    }
  }

  Future<User?> _pullAndSaveSpecificUser(String userId) async {
    try {
      final doc = await firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final userData = Map<String, dynamic>.from(data);
        if (!userData.containsKey('id')) userData['id'] = doc.id;
        final user = User.fromMap(userData);
        await _saveUserToDrift(user);
        return user;
      }
    } catch (e) {
      AppLogger.warning('Failed to pull specific user $userId: $e', name: 'admin.firestore.sync');
    }
    return null;
  }

  Future<void> _saveUserToDrift(User user) async {
    final existingRecord = await driftService.records.findByRemoteId(
      collectionName: _usersCollection,
      remoteId: user.id,
      enterpriseId: 'global',
      moduleType: 'administration',
    );

    final localId = existingRecord?.localId ?? user.id;

    await driftService.records.upsert(
      collectionName: _usersCollection,
      localId: localId,
      remoteId: user.id,
      enterpriseId: 'global',
      moduleType: 'administration',
      dataJson: jsonEncode(user.toMap()),
      localUpdatedAt: user.updatedAt ?? DateTime.now(),
    );
  }

  Future<void> _pullAndSaveEnterprises({List<String>? allowedEnterpriseIds}) async {
    try {
      final enterprises = await pullEnterprisesFromFirestore(allowedEnterpriseIds: allowedEnterpriseIds);
      for (final enterprise in enterprises) {
        await _saveEnterpriseToDrift(enterprise);
      }
    } catch (e) {
      AppLogger.warning('Failed to pull enterprises: $e', name: 'admin.firestore.sync');
    }
  }

  /// Helper unifié pour sauvegarder une entreprise au bon endroit (Root vs POS vs Agence)
  Future<void> _saveEnterpriseToDrift(Enterprise enterprise) async {
    // Déterminer la collection correcte
    String targetCollection = _enterprisesCollection; // Par défaut 'enterprises'
    
    // Règle métier : les sous-tenants vont dans des tables dédiées
    if (enterprise.type.isGas && !enterprise.type.isMain) {
      targetCollection = 'pointOfSale';
    } else if (enterprise.type.isMobileMoney && !enterprise.type.isMain) {
      targetCollection = 'agences';
    }

    final parentId = enterprise.parentEnterpriseId ?? 'global';
    
    // Déterminer le module propriétaire
    final moduleType = (!enterprise.type.isMain) 
        ? enterprise.type.module.id 
        : (enterprise.moduleId ?? 'administration');

    // On utilise l'ID remote comme local ID pour la synchronisation
    final recordId = enterprise.id;

    await driftService.records.upsert(
      userId: _currentUserId ?? '', 
      collectionName: targetCollection,
      localId: recordId,
      remoteId: recordId,
      enterpriseId: parentId,
      moduleType: moduleType,
      dataJson: jsonEncode(enterprise.toMap()),
      localUpdatedAt: DateTime.now(),
    );

    // Si c'était un sous-tenant indûment enregistré dans la collection racine 'enterprises', 
    // le supprimer pour éviter les doublons dans l'affichage.
    if (targetCollection != _enterprisesCollection) {
      await driftService.records.deleteByRemoteId(
        collectionName: _enterprisesCollection,
        remoteId: recordId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
    }
  }

  /// Alias utilisé pour la découverte des sous-tenants lors du pull initial
  Future<void> _saveSubTenantToDrift(Enterprise enterprise, String parentId) async {
    // On s'assure que le parent est bien positionné dans les données avant sauvegarde
    final updatedEnterprise = enterprise.parentEnterpriseId == parentId 
        ? enterprise 
        : enterprise.copyWith(parentEnterpriseId: parentId);
    await _saveEnterpriseToDrift(updatedEnterprise);
  }

  Future<void> _pullAndSaveRoles() async {
    final roles = await pullRolesFromFirestore();
    for (final role in roles) {
      final existingRecord = await driftService.records.findByRemoteId(
        collectionName: _rolesCollection,
        remoteId: role.id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final localId = existingRecord?.localId ?? role.id;

      await driftService.records.upsert(
        collectionName: _rolesCollection,
        localId: localId,
        remoteId: role.id,
        enterpriseId: 'global',
        moduleType: 'administration',
        dataJson: jsonEncode({
          'id': role.id,
          'name': role.name,
          'description': role.description,
          'permissions': role.permissions.toList(),
          'moduleId': role.moduleId, // Assure la persistance du module associé
          'isSystemRole': role.isSystemRole,
        }),
        localUpdatedAt: DateTime.now(),
      );
    }
  }

  
  Future<void> _saveEnterpriseModuleUserToDrift(EnterpriseModuleUser emu) async {
    final existingRecord = await driftService.records.findByRemoteId(
      collectionName: _enterpriseModuleUsersCollection,
      remoteId: emu.documentId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );

    final localId = existingRecord?.localId ?? emu.documentId;

    await driftService.records.upsert(
      collectionName: _enterpriseModuleUsersCollection,
      localId: localId,
      remoteId: emu.documentId,
      enterpriseId: 'global',
      moduleType: 'administration',
      dataJson: jsonEncode(emu.toMap()),
      localUpdatedAt: DateTime.now(),
    );
  }

  Future<void> _pullAndSaveEnterpriseModuleUsers({String? userId}) async {
    final emus = await pullEnterpriseModuleUsersFromFirestore(userId: userId);
    for (final emu in emus) {
      await _saveEnterpriseModuleUserToDrift(emu);
    }
  }

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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error syncing user to Firestore: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error syncing enterprise to Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Synchronise une entreprise spécifique par son ID.
  /// 
  /// Utile quand un utilisateur est assigné à un sous-tenant (ex: POS) 
  /// sans avoir l'entreprise parente synchronisée.
  Future<void> syncSpecificEnterprise(String enterpriseId) async {
    try {
      // 1. Tenter de récupérer dans la collection globale
      final enterpriseDoc = await firestore
          .collection(_enterprisesCollection)
          .doc(enterpriseId)
          .get();

      if (enterpriseDoc.exists) {
        await _saveEnterpriseToDrift(Enterprise.fromMap(enterpriseDoc.data()!));
        return;
      }

      // 2. Tenter de récupérer dans les sous-collections (via Collection Group)
      // On cherche dans 'pointsOfSale' (Gaz) et 'agences' (Mobile Money)
      for (final subName in ['pointsOfSale', 'agences']) {
        final groupSnapshot = await firestore
            .collectionGroup(subName)
            .where(FieldPath.documentId, isEqualTo: enterpriseId)
            .get();

        if (groupSnapshot.docs.isNotEmpty) {
          final doc = groupSnapshot.docs.first;
          final data = Map<String, dynamic>.from(doc.data());
          final parentId = doc.reference.parent.parent?.id;
          
          if (parentId != null) {
            final subTenant = Enterprise.fromMap({...data, 'id': doc.id, 'parentEnterpriseId': parentId});
            await _saveSubTenantToDrift(subTenant, parentId);
            return;
          }
        }
      }

      AppLogger.warning(
        'Enterprise $enterpriseId not found in Firestore (Global, pointsOfSale, or agences)',
        name: 'admin.firestore.sync',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error syncing specific enterprise $enterpriseId: $e',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }


  // Method removed and replaced by _saveEnterpriseToDrift above

  /// Sync a role to Firestore
  ///
  /// Throws an exception with a user-friendly message if the sync fails,
  /// especially for permission denied errors.
  Future<void> syncRoleToFirestore(
    UserRole role, {
    bool isUpdate = false,
  }) async {
    try {
      final roleDoc = firestore.collection(_rolesCollection).doc(role.id);
      final roleMap = {
        'id': role.id,
        'name': role.name,
        'description': role.description,
        'permissions': role.permissions.toList(),
        'moduleId': role.moduleId,
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error syncing role to Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );

      // Propager les erreurs de permission avec un message clair
      if (e.code == 'permission-denied') {
        throw AuthorizationException(
          'Permission refusée : Vous n\'avez pas les droits pour créer/modifier des rôles dans Firestore. '
          'Vérifiez que :\n'
          '1. Votre utilisateur a le flag isAdmin: true dans Firestore\n'
          '2. Les règles de sécurité Firestore permettent l\'écriture dans la collection "roles"\n'
          '3. Votre utilisateur est bien authentifié avec Firebase Auth',
          'FIRESTORE_PERMISSION_DENIED',
        );
      }

      // Propager les autres erreurs Firestore avec un message adapté
      throw SyncException(
        'Erreur lors de la synchronisation avec Firestore: ${e.message ?? e.code}',
        'FIRESTORE_SYNC_ERROR',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error syncing role to Firestore: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error syncing EnterpriseModuleUser to Firestore: ${appException.message}',
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error deleting from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );

      // Propager les erreurs de permission avec un message clair
      if (e.code == 'permission-denied') {
        throw AuthorizationException(
          'Permission refusée : Vous n\'avez pas les droits pour supprimer dans Firestore. '
          'Vérifiez que :\n'
          '1. Votre utilisateur a le flag isAdmin: true dans Firestore\n'
          '2. Les règles de sécurité Firestore permettent la suppression dans la collection "$collection"\n'
          '3. Votre utilisateur est bien authentifié avec Firebase Auth',
          'FIRESTORE_PERMISSION_DENIED',
        );
      }

      // Propager les autres erreurs Firestore avec un message adapté
      throw SyncException(
        'Erreur lors de la suppression dans Firestore: ${e.message ?? e.code}',
        'FIRESTORE_DELETE_ERROR',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error deleting from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Pull users from Firestore
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
          username:
              data['username'] as String? ??
              data['email']?.split('@').first ??
              '',
          email: data['email'] as String?,
          phone: data['phone'] as String?,
          isActive: data['isActive'] as bool? ?? true,
          enterpriseIds: (data['enterpriseIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Firebase error pulling users from Firestore (code: ${e.code}): ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error pulling users from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Pull enterprises from Firestore
  Future<List<Enterprise>> pullEnterprisesFromFirestore({List<String>? allowedEnterpriseIds}) async {
    try {
      final List<Enterprise> result = [];
      final Set<String> foundIds = {};

      // 1. Pull from root collection
      Query<Map<String, dynamic>> snapshotQuery = firestore.collection(_enterprisesCollection);
      
      if (allowedEnterpriseIds != null) {
        if (allowedEnterpriseIds.isEmpty) return [];
        
        // Split into chunks of 10 for 'whereIn'
        for (var i = 0; i < allowedEnterpriseIds.length; i += 10) {
          final chunk = allowedEnterpriseIds.sublist(
            i, 
            i + 10 > allowedEnterpriseIds.length ? allowedEnterpriseIds.length : i + 10,
          );
          final chunkSnapshot = await firestore
              .collection(_enterprisesCollection)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          
          for (final doc in chunkSnapshot.docs) {
            result.add(Enterprise.fromMap(doc.data()));
            foundIds.add(doc.id);
          }
        }
      } else {
        // Admin or all pull
        final snapshot = await snapshotQuery.get();
        result.addAll(snapshot.docs
            .map((doc) => Enterprise.fromMap(doc.data())));
            
        // Pour les admins, on doit aussi récupérer TOUS les sous-tenants
        // via collectionGroup sinon on ne les verra pas s'ils ne sont pas à la racine
        for (final subCollection in ['pointsOfSale', 'agences']) {
          try {
            final groupSnapshot = await firestore
                .collectionGroup(subCollection)
                .get();
            
            for (final doc in groupSnapshot.docs) {
              if (foundIds.contains(doc.id)) continue;
              
              final data = Map<String, dynamic>.from(doc.data());
              final parentId = doc.reference.parent.parent?.id;
              
              result.add(Enterprise.fromMap({
                ...data,
                'id': doc.id,
                'parentEnterpriseId': parentId,
              }));
              foundIds.add(doc.id);
            }
          } catch (e) {
            AppLogger.warning('Error pulling collectionGroup $subCollection: $e', name: 'admin.firestore.sync');
          }
        }
        
        return result;
      }

      // 2. Search for missing IDs in sub-collections (pointsOfSale and agences)
      final missingIds = allowedEnterpriseIds.where((id) => !foundIds.contains(id)).toList();
      
      if (missingIds.isNotEmpty) {
        for (final id in missingIds) {
          try {
            DocumentSnapshot<Map<String, dynamic>>? doc;
            
            if (id.startsWith('pos_')) {
              // Pattern: pos_{parentId}_{timestamp}
              final parts = id.split('_');
              if (parts.length >= 3) {
                final parentId = '${parts[1]}_${parts[2]}';
                doc = await firestore
                    .collection(_enterprisesCollection)
                    .doc(parentId)
                    .collection('pointsOfSale')
                    .doc(id)
                    .get();
              }
            } else if (id.startsWith('agence_')) {
              // Pattern: agence_{parentId}_{timestamp} ou agence_orange_money_{timestamp}
              final parts = id.split('_');
              if (parts.length >= 4 && parts[1] == 'orange' && parts[2] == 'money') {
                final parentId = '${parts[1]}_${parts[2]}_${parts[3]}';
                doc = await firestore
                    .collection(_enterprisesCollection)
                    .doc(parentId)
                    .collection('agences')
                    .doc(id)
                    .get();
              } else if (parts.length >= 3) {
                final parentId = '${parts[1]}_${parts[2]}';
                 doc = await firestore
                    .collection(_enterprisesCollection)
                    .doc(parentId)
                    .collection('agences')
                    .doc(id)
                    .get();
              }
            }

            if (doc != null && doc.exists) {
              final data = Map<String, dynamic>.from(doc.data()!);
              final parentId = doc.reference.parent.parent?.id;
              
              result.add(Enterprise.fromMap({
                ...data,
                'id': doc.id,
                'parentEnterpriseId': parentId,
              }));
              foundIds.add(doc.id);
            }
          } catch (e) {
             AppLogger.warning('Error pulling specific enterprise $id: $e', name: 'admin.firestore.sync');
          }
        }
      }

      return result;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error pulling enterprises from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
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
          permissions:
              (data['permissions'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toSet() ??
              {},
          moduleId: data['moduleId'] as String? ?? 'administration',
          isSystemRole: data['isSystemRole'] as bool? ?? false,
        );
      }).toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error pulling roles from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Pull EnterpriseModuleUsers from Firestore
  ///
  /// Si [userId] est fourni, ne récupère que les assignations de cet utilisateur.
  /// Sinon, récupère tout (admin seulement).
  Future<List<EnterpriseModuleUser>> pullEnterpriseModuleUsersFromFirestore({
    String? userId,
  }) async {
    try {
      Query query = firestore.collection(_enterpriseModuleUsersCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EnterpriseModuleUser.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error pulling EnterpriseModuleUsers from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Firebase error syncing audit log to Firestore (code: ${e.code}): ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - les erreurs de sync ne doivent pas bloquer l'application
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error syncing audit log to Firestore: ${appException.message}',
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
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        );
      }

      query = query.orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          throw NotFoundException(
            'Document data is null for audit log: ${doc.id}',
            'AUDIT_LOG_DATA_NULL',
          );
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Firebase error pulling audit logs from Firestore (code: ${e.code}): ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error pulling audit logs from Firestore: ${appException.message}',
        name: 'admin.firestore.sync',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}

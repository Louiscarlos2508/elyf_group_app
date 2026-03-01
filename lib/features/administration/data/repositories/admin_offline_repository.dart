import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/sync_status.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/admin_repository.dart';
import 'optimized_queries.dart';

/// Offline-first repository for Admin operations (roles and enterprise module users).
class AdminOfflineRepository implements AdminRepository {
  AdminOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    this.userRepository,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final UserRepository? userRepository;

  static const String _rolesCollection = 'roles';
  static const String _enterpriseModuleUsersCollection =
      'enterprise_module_users';

  // EnterpriseModuleUser methods
  EnterpriseModuleUser _enterpriseModuleUserFromMap(Map<String, dynamic> map) {
    return EnterpriseModuleUser.fromMap(map);
  }

  Map<String, dynamic> _enterpriseModuleUserToMap(EnterpriseModuleUser entity) {
    return {
      'userId': entity.userId,
      'enterpriseId': entity.enterpriseId,
      'moduleId': entity.moduleId,
      'roleIds': entity.roleIds,
      'customPermissions': entity.customPermissions.toList(),
      'isActive': entity.isActive,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  // UserRole methods
  UserRole _userRoleFromMap(Map<String, dynamic> map) {
    return UserRole(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      permissions:
          (map['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      moduleId: map['moduleId'] as String? ?? 'administration',
      isSystemRole: map['isSystemRole'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _userRoleToMap(UserRole entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'description': entity.description,
      'permissions': entity.permissions.toList(),
      'moduleId': entity.moduleId,
      'isSystemRole': entity.isSystemRole,
    };
  }

  String _getLocalId(String id) {
    if (id.startsWith('local_')) {
      return id;
    }
    // Utiliser un ID local déterministe basé sur l'ID du rôle
    // pour que l'upsert mette à jour le bon enregistrement
    return 'local_$id';
  }

  String? _getRemoteId(String id) {
    if (!id.startsWith('local_')) {
      return id;
    }
    return null;
  }

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _enterpriseModuleUsersCollection,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      
      final assignments = records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return _enterpriseModuleUserFromMap(map);
      }).toList();
      
      final uniqueAssignments = <String, EnterpriseModuleUser>{};
      for (final assignment in assignments) {
        final documentId = assignment.documentId;
        final existing = uniqueAssignments[documentId];
        
        if (existing == null) {
          uniqueAssignments[documentId] = assignment;
        } else {
          final existingDate = existing.updatedAt ?? existing.createdAt;
          final currentDate = assignment.updatedAt ?? assignment.createdAt;
          
          if (currentDate != null && 
              (existingDate == null || currentDate.isAfter(existingDate))) {
            uniqueAssignments[documentId] = assignment;
          }
        }
      }
      
      return uniqueAssignments.values.toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<EnterpriseModuleUser>> watchEnterpriseModuleUsers() {
    return driftService.records
        .watchForEnterprise(
          collectionName: _enterpriseModuleUsersCollection,
          enterpriseId: 'global',
          moduleType: 'administration',
        )
        .map((records) {
      final assignments = records.map((record) {
        try {
          final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
          return _enterpriseModuleUserFromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<EnterpriseModuleUser>().toList();

      final uniqueAssignments = <String, EnterpriseModuleUser>{};
      for (final assignment in assignments) {
        final documentId = assignment.documentId;
        final existing = uniqueAssignments[documentId];

        if (existing == null) {
          uniqueAssignments[documentId] = assignment;
        } else {
          final existingDate = existing.updatedAt ?? existing.createdAt;
          final currentDate = assignment.updatedAt ?? assignment.createdAt;

          if (currentDate != null &&
              (existingDate == null || currentDate.isAfter(existingDate))) {
            uniqueAssignments[documentId] = assignment;
          }
        }
      }

      return uniqueAssignments.values.toList();
    });
  }

  @override
  Future<List<EnterpriseModuleUser>> getUserEnterpriseModuleUsers(
    String userId,
  ) async {
    final all = await getEnterpriseModuleUsers();
    return all.where((emu) => emu.userId == userId).toList();
  }

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseUsers(
    String enterpriseId,
  ) async {
    final all = await getEnterpriseModuleUsers();
    return all.where((emu) => emu.enterpriseId == enterpriseId).toList();
  }

  @override
  Future<List<EnterpriseModuleUser>>
  getEnterpriseModuleUsersByEnterpriseAndModule(
    String enterpriseId,
    String moduleId,
  ) async {
    final all = await getEnterpriseModuleUsers();
    return all
        .where(
          (emu) => emu.enterpriseId == enterpriseId && emu.moduleId == moduleId,
        )
        .toList();
  }

  @override
  Future<EnterpriseModuleUser?> getUserEnterpriseModuleUser({
    required String userId,
    required String enterpriseId,
    required String moduleId,
  }) async {
    final all = await getEnterpriseModuleUsers();
    try {
      return all.firstWhere(
        (emu) =>
            emu.userId == userId &&
            emu.enterpriseId == enterpriseId &&
            emu.moduleId == moduleId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser,
  ) async {
    // Utiliser le documentId comme localId pour garantir l'unicité
    // Le documentId est unique: userId_enterpriseId_moduleId
    final documentId = enterpriseModuleUser.documentId;
    
    // Chercher d'abord un enregistrement existant par remoteId (documentId)
    // pour éviter les doublons si un enregistrement existe déjà avec un localId différent
    final existingRecord = await driftService.records.findByRemoteId(
      collectionName: _enterpriseModuleUsersCollection,
      remoteId: documentId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    
    // Utiliser le localId existant si trouvé, sinon utiliser le documentId
    final localId = existingRecord?.localId ?? documentId;
    final remoteId = documentId; // Le documentId est toujours le remoteId
    
    final map = _enterpriseModuleUserToMap(enterpriseModuleUser)
      ..['localId'] = localId;
    
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: _enterpriseModuleUsersCollection,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: 'global',
      moduleType: 'administration',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );

    // Queue sync operation (background)
    await syncManager.queueUpdate(
      collectionName: _enterpriseModuleUsersCollection,
      localId: localId,
      remoteId: remoteId,
      data: _enterpriseModuleUserToMap(enterpriseModuleUser),
      enterpriseId: 'global',
    );

    // Mettre à jour les enterpriseIds dans le document utilisateur pour les règles Firestore
    await _syncUserEnterpriseIds(enterpriseModuleUser.userId);
  }

  @override
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    List<String> roleIds,
  ) async {
    final all = await getEnterpriseModuleUsers();
    final emu = all.firstWhere(
      (e) =>
          e.userId == userId &&
          e.enterpriseId == enterpriseId &&
          e.moduleId == moduleId,
      orElse: () => EnterpriseModuleUser(
        userId: syncManager.getUserId() ?? '',
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        roleIds: roleIds,
      ),
    );
    await assignUserToEnterprise(emu.copyWith(roleIds: roleIds));
  }

  @override
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions,
  ) async {
    final all = await getEnterpriseModuleUsers();
    final emu = all.firstWhere(
      (e) =>
          e.userId == userId &&
          e.enterpriseId == enterpriseId &&
          e.moduleId == moduleId,
      orElse: () => EnterpriseModuleUser(
        userId: syncManager.getUserId() ?? '',
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        roleIds: const [], // Default roles
      ),
    );
    await assignUserToEnterprise(emu.copyWith(customPermissions: permissions));
  }

  @override
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    // Le documentId est utilisé comme remoteId dans Drift
    // Il faut utiliser deleteByRemoteId avec le documentId
    final documentId = '${userId}_${enterpriseId}_$moduleId';
    
    // Récupérer le localId avant la suppression pour pouvoir le passer à queueDelete
    final record = await driftService.records.findByRemoteId(
      collectionName: _enterpriseModuleUsersCollection,
      remoteId: documentId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    
    final localId = record?.localId ?? documentId;
    
    // Utiliser une transaction pour garantir l'atomicité
    await driftService.db.transaction(() async {
      // 1. Supprimer localement
      await driftService.records.deleteByRemoteId(
        collectionName: _enterpriseModuleUsersCollection,
        remoteId: documentId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      
      // 2. Mettre en file d'attente la suppression pour synchronisation vers Firestore
      // Cela garantit que la suppression sera retentée si elle échoue (réseau, permissions, etc.)
      await syncManager.queueDelete(
        collectionName: _enterpriseModuleUsersCollection,
        localId: localId,
        remoteId: documentId,
        enterpriseId: 'global',
      );
      
      developer.log(
        'EnterpriseModuleUser deletion queued: $documentId (localId: $localId)',
        name: 'admin.repository',
      );
    });

    // Mettre à jour les enterpriseIds dans le document utilisateur pour les règles Firestore
    await _syncUserEnterpriseIds(userId);
  }

  /// Synchronise les enterpriseIds dans le document utilisateur Firestore
  /// pour que les règles de sécurité Firestore fonctionnent.
  Future<void> _syncUserEnterpriseIds(String userId) async {
    if (userRepository == null) return;

    try {
      // 1. Récupérer toutes les assignations de l'utilisateur
      final assignments = await getUserEnterpriseModuleUsers(userId);
      
      // 2. Extraire les IDs d'entreprise uniques (y compris les parents pour les sous-tenants)
      final directIds = assignments
          .where((a) => a.isActive)
          .map((a) => a.enterpriseId)
          .toSet();
      
      final enterpriseIdsSet = <String>{...directIds};
      
      // Propager les IDs parents pour les sous-tenants (POS/Agences)
      // Cela permet aux règles Firestore de donner accès aux ressources partagées du parent
      for (final id in directIds) {
        if (id.startsWith('pos_')) {
          final parts = id.split('_');
          if (parts.length >= 3) {
            enterpriseIdsSet.add('${parts[1]}_${parts[2]}');
          }
        } else if (id.startsWith('agence_')) {
          final parts = id.split('_');
          if (parts.length >= 4 && parts[1] == 'orange' && parts[2] == 'money') {
             enterpriseIdsSet.add('${parts[1]}_${parts[2]}_${parts[3]}');
          } else if (parts.length >= 3) {
             enterpriseIdsSet.add('${parts[1]}_${parts[2]}');
          }
        }
      }
      
      final enterpriseIds = enterpriseIdsSet.toList();

      // 3. Récupérer l'utilisateur
      final user = await userRepository!.getUserById(userId);
      if (user != null) {
        // 4. Mettre à jour l'utilisateur avec les nouveaux enterpriseIds
        final updatedUser = user.copyWith(
          enterpriseIds: enterpriseIds,
          updatedAt: DateTime.now(),
        );
        
        // 5. Sauvegarder l'utilisateur (cela déclenchera la sync vers Firestore)
        await userRepository!.updateUser(updatedUser);
        
        developer.log(
          '✅ User enterpriseIds synced: ${user.id}, count: ${enterpriseIds.length}',
          name: 'admin.repository',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to sync user enterpriseIds: $e',
        name: 'admin.repository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<UserRole>> getAllRoles() async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: _rolesCollection,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      return records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return _userRoleFromMap(map);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<UserRole>> watchAllRoles() {
    return driftService.records
        .watchForEnterprise(
          collectionName: _rolesCollection,
          enterpriseId: 'global',
          moduleType: 'administration',
        )
        .map((records) {
      return records.map((record) {
        try {
          final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
          return _userRoleFromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<UserRole>().toList();
    });
  }

  @override
  Future<({List<UserRole> roles, int totalCount})> getRolesPaginated({
    int page = 0,
    int limit = 50,
  }) async {
    try {
      // Validate and clamp pagination parameters
      final validated = OptimizedQueries.validatePagination(
        page: page,
        limit: limit,
      );
      final offset = OptimizedQueries.calculateOffset(
        validated.page,
        validated.limit,
      );

      // Get paginated records using LIMIT/OFFSET at Drift level
      final records = await driftService.records.listForEnterprisePaginated(
        collectionName: _rolesCollection,
        enterpriseId: 'global',
        moduleType: 'administration',
        limit: validated.limit,
        offset: offset,
      );

      // Get total count for pagination info
      final totalCount = await driftService.records.countForEnterprise(
        collectionName: _rolesCollection,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final roles = records.map<UserRole>((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return _userRoleFromMap(map);
      }).toList();

      return (roles: roles, totalCount: totalCount);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching paginated roles from offline storage: ${appException.message}',
        name: 'admin.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return (roles: <UserRole>[], totalCount: 0);
    }
  }

  Future<UserRole?> getRoleById(String roleId) async {
    final allRoles = await getAllRoles();
    try {
      return allRoles.firstWhere((role) => role.id == roleId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> createRole(UserRole role) async {
    final localId = _getLocalId(role.id);
    final remoteId = _getRemoteId(role.id);
    final map = _userRoleToMap(role)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: _rolesCollection,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: 'global',
      moduleType: 'administration',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );

    // Queue sync operation (background)
    await syncManager.queueUpdate(
      collectionName: _rolesCollection,
      localId: localId,
      remoteId: remoteId ?? role.id,
      data: _userRoleToMap(role),
      enterpriseId: 'global',
    );
    return role.id;
  }

  @override
  Future<void> updateRole(UserRole role) async {
    await createRole(role); // upsert handles both create and update
  }

  @override
  Future<void> deleteRole(String roleId) async {
    // Récupérer le rôle pour obtenir le localId
    final role = await getRoleById(roleId);
    if (role == null) {
      developer.log(
        'Role not found for deletion: $roleId',
        name: 'admin.repository',
      );
      return;
    }

    final localId = _getLocalId(roleId);
    // remoteId: si roleId ne commence pas par 'local_', c'est lui-même le remoteId
    final remoteId = _getRemoteId(roleId) ?? (roleId.startsWith('local_') ? null : roleId);

    developer.log(
      'AdminOfflineRepository.deleteRole: $_rolesCollection/$localId (remoteId=$remoteId)',
      name: 'admin.repository',
    );

    // Delete from local storage — essayer par remoteId d'abord, puis par localId
    // pour couvrir tous les patterns de stockage possibles.
    try {
      await driftService.records.deleteByRemoteId(
        collectionName: _rolesCollection,
        remoteId: roleId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
    } catch (_) {
      // Si la suppression par remoteId échoue, essayer par localId
    }
    try {
      await driftService.records.deleteByLocalId(
        collectionName: _rolesCollection,
        localId: localId,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
    } catch (_) {
      // Ignorer si déjà supprimé
    }

    // Queue sync operation vers Firestore si le rôle a un remoteId
    if (remoteId != null && remoteId.isNotEmpty) {
      await syncManager.queueDelete(
        collectionName: _rolesCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: 'global',
      );
    }
  }

  @override
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    final allRoles = await getAllRoles();
    return allRoles.where((role) => role.moduleId == moduleId).toList();
  }

  @override
  Stream<bool> watchSyncStatus() {
    return syncManager.syncProgressStream.map((progress) => progress.status == SyncStatus.syncing);
  }
}

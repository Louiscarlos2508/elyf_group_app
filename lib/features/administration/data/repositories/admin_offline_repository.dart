import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../domain/repositories/admin_repository.dart';
import 'optimized_queries.dart';

/// Offline-first repository for Admin operations (roles and enterprise module users).
class AdminOfflineRepository implements AdminRepository {
  AdminOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;

  static const String _rolesCollection = 'roles';
  static const String _enterpriseModuleUsersCollection =
      'enterprise_module_users';

  // EnterpriseModuleUser methods
  EnterpriseModuleUser _enterpriseModuleUserFromMap(Map<String, dynamic> map) {
    return EnterpriseModuleUser(
      userId: map['userId'] as String,
      enterpriseId: map['enterpriseId'] as String,
      moduleId: map['moduleId'] as String,
      roleId: map['roleId'] as String,
      customPermissions:
          (map['customPermissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _enterpriseModuleUserToMap(EnterpriseModuleUser entity) {
    return {
      'userId': entity.userId,
      'enterpriseId': entity.enterpriseId,
      'moduleId': entity.moduleId,
      'roleId': entity.roleId,
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
      isSystemRole: map['isSystemRole'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _userRoleToMap(UserRole entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'description': entity.description,
      'permissions': entity.permissions.toList(),
      'isSystemRole': entity.isSystemRole,
    };
  }

  String _getLocalId(String id) {
    if (id.startsWith('local_')) {
      return id;
    }
    return LocalIdGenerator.generate();
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
      return records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return _enterpriseModuleUserFromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching enterprise module users from offline storage',
        name: 'admin.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
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
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser,
  ) async {
    final localId = _getLocalId(enterpriseModuleUser.documentId);
    final remoteId = _getRemoteId(enterpriseModuleUser.documentId);
    final map = _enterpriseModuleUserToMap(enterpriseModuleUser)
      ..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: _enterpriseModuleUsersCollection,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: 'global',
      moduleType: 'administration',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    String roleId,
  ) async {
    final all = await getEnterpriseModuleUsers();
    final emu = all.firstWhere(
      (e) =>
          e.userId == userId &&
          e.enterpriseId == enterpriseId &&
          e.moduleId == moduleId,
      orElse: () => EnterpriseModuleUser(
        userId: userId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        roleId: roleId,
      ),
    );
    await assignUserToEnterprise(emu.copyWith(roleId: roleId));
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
        userId: userId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        roleId: 'vendeur', // Default role
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
    await driftService.records.deleteByRemoteId(
      collectionName: _enterpriseModuleUsersCollection,
      remoteId: documentId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
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
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching roles from offline storage',
        name: 'admin.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
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
      developer.log(
        'Error fetching paginated roles from offline storage',
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
    await driftService.records.upsert(
      collectionName: _rolesCollection,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: 'global',
      moduleType: 'administration',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
    return role.id;
  }

  @override
  Future<void> updateRole(UserRole role) async {
    await createRole(role); // upsert handles both create and update
  }

  @override
  Future<void> deleteRole(String roleId) async {
    // Le roleId est utilisé comme remoteId dans Drift
    // Il faut utiliser deleteByRemoteId avec le roleId
    await driftService.records.deleteByRemoteId(
      collectionName: _rolesCollection,
      remoteId: roleId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
  }

  @override
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    // For now, return all roles. In real implementation, filter by module permissions
    final allRoles = await getAllRoles();
    return allRoles;
  }
}

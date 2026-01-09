import '../../../../../core/permissions/services/permission_service.dart';
import '../../../../../core/permissions/entities/user_role.dart';

/// Service for validating permissions before performing actions.
/// 
/// Ensures users have the required permissions before allowing actions.
class PermissionValidatorService {
  PermissionValidatorService({
    required this.permissionService,
  });

  final PermissionService permissionService;

  /// Check if user has permission to perform an action
  Future<bool> hasPermission({
    required String userId,
    required String moduleId,
    required String permissionId,
  }) async {
    return await permissionService.hasPermission(
      userId,
      moduleId,
      permissionId,
    );
  }

  /// Check if user has any of the required permissions
  Future<bool> hasAnyPermission({
    required String userId,
    required String moduleId,
    required Set<String> permissionIds,
  }) async {
    return await permissionService.hasAnyPermission(
      userId,
      moduleId,
      permissionIds,
    );
  }

  /// Check if user has all required permissions
  Future<bool> hasAllPermissions({
    required String userId,
    required String moduleId,
    required Set<String> permissionIds,
  }) async {
    return await permissionService.hasAllPermissions(
      userId,
      moduleId,
      permissionIds,
    );
  }

  /// Check if user has admin permission for a module
  Future<bool> isModuleAdmin({
    required String userId,
    required String moduleId,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: moduleId,
      permissionId: '*',
    );
  }

  /// Check if user can create entities in a module
  Future<bool> canCreate({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: moduleId,
      permissionId: 'create_$entityType',
    ) || await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Check if user can update entities in a module
  Future<bool> canUpdate({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: moduleId,
      permissionId: 'update_$entityType',
    ) || await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Check if user can delete entities in a module
  Future<bool> canDelete({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: moduleId,
      permissionId: 'delete_$entityType',
    ) || await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Check if user can view entities in a module
  Future<bool> canView({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: moduleId,
      permissionId: 'view_$entityType',
    ) || await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Validate admin permissions
  /// 
  /// Admin-specific permissions for administration module
  Future<bool> canManageUsers({
    required String userId,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: 'administration',
      permissionId: 'manage_users',
    );
  }

  Future<bool> canManageRoles({
    required String userId,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: 'administration',
      permissionId: 'manage_roles',
    );
  }

  Future<bool> canManageEnterprises({
    required String userId,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: 'administration',
      permissionId: 'manage_enterprises',
    );
  }
}


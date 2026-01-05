import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';

/// Repository for administration operations with multi-tenant support.
abstract class AdminRepository {
  /// Get all enterprise module users (all accesses)
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers();

  /// Get enterprise module users for a specific user
  Future<List<EnterpriseModuleUser>> getUserEnterpriseModuleUsers(String userId);

  /// Get enterprise module users for a specific enterprise
  Future<List<EnterpriseModuleUser>> getEnterpriseUsers(String enterpriseId);

  /// Get enterprise module users for a specific enterprise and module
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsersByEnterpriseAndModule(
    String enterpriseId,
    String moduleId,
  );

  /// Assign a user to an enterprise and module with a role
  Future<void> assignUserToEnterprise(EnterpriseModuleUser enterpriseModuleUser);

  /// Update a user's role in an enterprise and module
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    String roleId,
  );

  /// Update user's custom permissions in an enterprise and module
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions,
  );

  /// Remove a user from an enterprise and module
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId,
  );

  /// Get all roles
  Future<List<UserRole>> getAllRoles();

  /// Get roles for a module
  Future<List<UserRole>> getModuleRoles(String moduleId);

  /// Create a new role
  Future<void> createRole(UserRole role);

  /// Update a role
  Future<void> updateRole(UserRole role);

  /// Delete a role (if not system role)
  Future<void> deleteRole(String roleId);
}


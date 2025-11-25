import '../../../../core/permissions/entities/module_user.dart';
import '../../../../core/permissions/entities/user_role.dart';

/// Repository for administration operations.
abstract class AdminRepository {
  /// Get all users in a module
  Future<List<ModuleUser>> getModuleUsers(String moduleId);

  /// Add a user to a module
  Future<void> addUserToModule(ModuleUser moduleUser);

  /// Update a user's role in a module
  Future<void> updateUserRole(
    String userId,
    String moduleId,
    String roleId,
  );

  /// Update user's custom permissions
  Future<void> updateUserPermissions(
    String userId,
    String moduleId,
    Set<String> permissions,
  );

  /// Remove a user from a module
  Future<void> removeUserFromModule(String userId, String moduleId);

  /// Get all roles
  Future<List<UserRole>> getAllRoles();

  /// Create a new role
  Future<void> createRole(UserRole role);

  /// Update a role
  Future<void> updateRole(UserRole role);

  /// Delete a role (if not system role)
  Future<void> deleteRole(String roleId);

  /// Get roles for a module
  Future<List<UserRole>> getModuleRoles(String moduleId);
}


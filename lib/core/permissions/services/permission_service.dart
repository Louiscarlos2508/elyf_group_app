import '../entities/module_user.dart';
import '../entities/user_role.dart';

/// Service for checking user permissions across all modules.
abstract class PermissionService {
  /// Check if user has a specific permission in a module
  Future<bool> hasPermission(
    String userId,
    String moduleId,
    String permissionId,
  );

  /// Get user's role in a module
  Future<UserRole?> getUserRole(String userId, String moduleId);

  /// Get user's module data
  Future<ModuleUser?> getModuleUser(String userId, String moduleId);

  /// Get all permissions for a user in a module
  Future<Set<String>> getUserPermissions(String userId, String moduleId);

  /// Check if user has any of the specified permissions
  Future<bool> hasAnyPermission(
    String userId,
    String moduleId,
    Set<String> permissionIds,
  );

  /// Check if user has all specified permissions
  Future<bool> hasAllPermissions(
    String userId,
    String moduleId,
    Set<String> permissionIds,
  );
}

/// Mock implementation for development
class MockPermissionService implements PermissionService {
  final Map<String, Map<String, ModuleUser>> _moduleUsers = {};
  final Map<String, UserRole> _roles = {};

  MockPermissionService({bool initializeDefaults = true}) {
    // Initialize with default roles
    _initializeDefaultRoles();

    // Initialize default users if requested
    if (initializeDefaults) {
      _initializeDefaultUsers();
    }
  }

  void _initializeDefaultRoles() {
    // System admin role
    _roles['admin'] = const UserRole(
      id: 'admin',
      name: 'Administrateur',
      description: 'Accès complet à tous les modules',
      permissions: {'*'}, // Wildcard for all permissions
      moduleId: 'administration',
      isSystemRole: true,
    );
  }

  void _initializeDefaultUsers() {
    final modules = [
      'eau_minerale',
      'gaz',
      'orange_money',
      'immobilier',
      'boutique',
    ];

    for (final moduleId in modules) {
      // Create admin role for the module if it doesn't exist
      final adminRoleId = 'admin_$moduleId';
      if (!_roles.containsKey(adminRoleId)) {
        _roles[adminRoleId] = UserRole(
          id: adminRoleId,
          name: 'Administrateur',
          description: 'Accès complet au module $moduleId',
          permissions: {'*'}, // Wildcard for all permissions
          moduleId: moduleId,
          isSystemRole: true,
        );
      }

      // Create default user for the module with full access
      final defaultUserId = 'default_user_$moduleId';
      _moduleUsers.putIfAbsent(moduleId, () => {});
      _moduleUsers[moduleId]![defaultUserId] = ModuleUser(
        userId: defaultUserId,
        moduleId: moduleId,
        roleId: adminRoleId,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Add a user to a module with a role
  void addUserToModule(ModuleUser moduleUser) {
    _moduleUsers.putIfAbsent(moduleUser.moduleId, () => {});
    _moduleUsers[moduleUser.moduleId]![moduleUser.userId] = moduleUser;
  }

  /// Create or update a role
  void upsertRole(UserRole role) {
    _roles[role.id] = role;
  }

  /// Get a role by ID
  UserRole? getRole(String roleId) {
    return _roles[roleId];
  }

  /// Get all roles
  List<UserRole> getAllRoles() {
    return _roles.values.toList();
  }

  @override
  Future<bool> hasPermission(
    String userId,
    String moduleId,
    String permissionId,
  ) async {
    final moduleUser = await getModuleUser(userId, moduleId);
    if (moduleUser == null || !moduleUser.isActive) {
      return false;
    }

    final role = await getUserRole(userId, moduleId);
    if (role == null) {
      return false;
    }

    // Check if role has wildcard permission
    if (role.hasPermission('*')) {
      return true;
    }

    // Check role permissions
    if (role.hasPermission(permissionId)) {
      return true;
    }

    // Check custom permissions
    return moduleUser.customPermissions.contains(permissionId);
  }

  @override
  Future<UserRole?> getUserRole(String userId, String moduleId) async {
    final moduleUser = await getModuleUser(userId, moduleId);
    if (moduleUser == null) {
      return null;
    }

    return _roles[moduleUser.roleId];
  }

  @override
  Future<ModuleUser?> getModuleUser(String userId, String moduleId) async {
    return _moduleUsers[moduleId]?[userId];
  }

  @override
  Future<Set<String>> getUserPermissions(String userId, String moduleId) async {
    final role = await getUserRole(userId, moduleId);
    if (role == null) {
      return {};
    }

    final permissions = <String>{...role.permissions};

    final moduleUser = await getModuleUser(userId, moduleId);
    if (moduleUser != null) {
      permissions.addAll(moduleUser.customPermissions);
    }

    return permissions;
  }

  @override
  Future<bool> hasAnyPermission(
    String userId,
    String moduleId,
    Set<String> permissionIds,
  ) async {
    for (final permissionId in permissionIds) {
      if (await hasPermission(userId, moduleId, permissionId)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> hasAllPermissions(
    String userId,
    String moduleId,
    Set<String> permissionIds,
  ) async {
    for (final permissionId in permissionIds) {
      if (!await hasPermission(userId, moduleId, permissionId)) {
        return false;
      }
    }
    return true;
  }
}

import '../entities/module_user.dart';
import '../entities/user_role.dart';
import '../../auth/entities/enterprise_module_user.dart';

/// Service for checking user permissions across all modules.
abstract class PermissionService {
  /// Check if user has a specific permission in a module
  Future<bool> hasPermission(
    String userId,
    String moduleId,
    String permissionId, {
    String? enterpriseId, // Added for multi-tenancy
  });

  /// Get user's role in a module
  Future<UserRole?> getUserRole(
    String userId,
    String moduleId, {
    String? enterpriseId, // Added for multi-tenancy
  });

  /// Get user's module data
  Future<ModuleUser?> getModuleUser(
    String userId,
    String moduleId, {
    String? enterpriseId, // Added for multi-tenancy
  });

  /// Get all permissions for a user in a module
  Future<Set<String>> getUserPermissions(
    String userId,
    String moduleId, {
    String? enterpriseId, // Added for multi-tenancy
  });

  /// Check if user has any of the specified permissions
  Future<bool> hasAnyPermission(
    String userId,
    String moduleId,
    Set<String> permissionIds, {
    String? enterpriseId, // Added for multi-tenancy
  });

  /// Check if user has all specified permissions
  Future<bool> hasAllPermissions(
    String userId,
    String moduleId,
    Set<String> permissionIds, {
    String? enterpriseId, // Added for multi-tenancy
  });

  /// Get user's access data for a specific enterprise and module.
  Future<EnterpriseModuleUser?> getEnterpriseModuleUser(
    String userId,
    String enterpriseId,
    String moduleId,
  );

  /// Get all active accesses for a user across all enterprises.
  Future<List<EnterpriseModuleUser>> getUserAccesses(String userId);

  /// Get IDs of all enterprises where the user has at least one active access.
  Future<List<String>> getUserEnterprises(String userId);

  /// Get IDs of all modules accessible by the user within a specific enterprise.
  Future<List<String>> getUserModules(String userId, String enterpriseId);

  /// Check if user has active access to a specific enterprise.
  Future<bool> hasEnterpriseAccess(String userId, String enterpriseId);

  /// Check if user has active access to a module within an enterprise.
  Future<bool> hasModuleAccess(
    String userId,
    String enterpriseId,
    String moduleId,
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
    String permissionId, {
    String? enterpriseId,
  }) async {
    final moduleUser = await getModuleUser(userId, moduleId, enterpriseId: enterpriseId);
    if (moduleUser == null || !moduleUser.isActive) {
      return false;
    }

    final role = await getUserRole(userId, moduleId, enterpriseId: enterpriseId);
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
  Future<UserRole?> getUserRole(
    String userId,
    String moduleId, {
    String? enterpriseId,
  }) async {
    final moduleUser = await getModuleUser(userId, moduleId, enterpriseId: enterpriseId);
    if (moduleUser == null) {
      return null;
    }

    return _roles[moduleUser.roleId];
  }

  @override
  Future<ModuleUser?> getModuleUser(
    String userId,
    String moduleId, {
    String? enterpriseId,
  }) async {
    return _moduleUsers[moduleId]?[userId];
  }

  @override
  Future<Set<String>> getUserPermissions(
    String userId,
    String moduleId, {
    String? enterpriseId,
  }) async {
    final role = await getUserRole(userId, moduleId, enterpriseId: enterpriseId);
    if (role == null) {
      return {};
    }

    final permissions = <String>{...role.permissions};

    final moduleUser = await getModuleUser(userId, moduleId, enterpriseId: enterpriseId);
    if (moduleUser != null) {
      permissions.addAll(moduleUser.customPermissions);
    }

    return permissions;
  }

  @override
  Future<bool> hasAnyPermission(
    String userId,
    String moduleId,
    Set<String> permissionIds, {
    String? enterpriseId,
  }) async {
    for (final permissionId in permissionIds) {
      if (await hasPermission(userId, moduleId, permissionId, enterpriseId: enterpriseId)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> hasAllPermissions(
    String userId,
    String moduleId,
    Set<String> permissionIds, {
    String? enterpriseId,
  }) async {
    for (final permissionId in permissionIds) {
      if (!await hasPermission(userId, moduleId, permissionId, enterpriseId: enterpriseId)) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<EnterpriseModuleUser?> getEnterpriseModuleUser(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    final moduleUser = await getModuleUser(userId, moduleId, enterpriseId: enterpriseId);
    if (moduleUser == null) return null;

    return EnterpriseModuleUser(
      userId: moduleUser.userId,
      enterpriseId: enterpriseId,
      moduleId: moduleUser.moduleId,
      roleIds: [moduleUser.roleId],
      customPermissions: moduleUser.customPermissions,
      isActive: moduleUser.isActive,
      createdAt: moduleUser.createdAt,
      updatedAt: moduleUser.updatedAt,
    );
  }

  @override
  Future<List<EnterpriseModuleUser>> getUserAccesses(String userId) async {
    final accesses = <EnterpriseModuleUser>[];
    for (final moduleId in _moduleUsers.keys) {
      final user = _moduleUsers[moduleId]?[userId];
      if (user != null && user.isActive) {
        accesses.add(EnterpriseModuleUser(
          userId: user.userId,
          enterpriseId: 'default_enterprise', // Mock fallback
          moduleId: user.moduleId,
          roleIds: [user.roleId],
          customPermissions: user.customPermissions,
          isActive: user.isActive,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        ));
      }
    }
    return accesses;
  }

  @override
  Future<List<String>> getUserEnterprises(String userId) async {
    final accesses = await getUserAccesses(userId);
    return accesses.map((a) => a.enterpriseId).toSet().toList();
  }

  @override
  Future<List<String>> getUserModules(String userId, String enterpriseId) async {
    final accesses = await getUserAccesses(userId);
    return accesses
        .where((a) => a.enterpriseId == enterpriseId)
        .map((a) => a.moduleId)
        .toList();
  }

  @override
  Future<bool> hasEnterpriseAccess(String userId, String enterpriseId) async {
    final accesses = await getUserAccesses(userId);
    return accesses.any((a) => a.enterpriseId == enterpriseId);
  }

  @override
  Future<bool> hasModuleAccess(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    final access = await getEnterpriseModuleUser(userId, enterpriseId, moduleId);
    return access != null && access.isActive;
  }
}

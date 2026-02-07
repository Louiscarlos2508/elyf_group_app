import '../entities/module_permission.dart';

/// Registry for all module permissions across the application.
class PermissionRegistry {
  PermissionRegistry._();

  static final PermissionRegistry instance = PermissionRegistry._();

  final Map<String, Map<String, ModulePermission>> _permissions = {};

  /// Register permissions for a module
  void registerModulePermissions(
    String moduleId,
    List<ModulePermission> permissions,
  ) {
    _permissions[moduleId] = {for (final perm in permissions) perm.id: perm};
  }

  /// Get all permissions for a module
  Map<String, ModulePermission>? getModulePermissions(String moduleId) {
    return _permissions[moduleId];
  }

  /// Get a specific permission
  ModulePermission? getPermission(String moduleId, String permissionId) {
    return _permissions[moduleId]?[permissionId];
  }

  /// Get all registered modules
  Set<String> get registeredModules => _permissions.keys.toSet();

  /// Check if a permission exists
  bool hasPermission(String moduleId, String permissionId) {
    return _permissions[moduleId]?.containsKey(permissionId) ?? false;
  }

  /// Get all permissions from all modules
  /// Returns a map of moduleId -> list of permission IDs
  Map<String, List<String>> getAllPermissions() {
    final result = <String, List<String>>{};
    for (final moduleId in _permissions.keys) {
      final modulePerms = _permissions[moduleId];
      if (modulePerms != null) {
        result[moduleId] = modulePerms.keys.toList()..sort();
      }
    }
    return result;
  }

  /// Get total count of registered permissions
  int get totalPermissionsCount {
    var count = 0;
    for (final modulePerms in _permissions.values) {
      count += modulePerms.length;
    }
    return count;
  }

  /// Get the module ID for a specific permission ID
  String? getModuleForPermission(String permissionId) {
    for (final entry in _permissions.entries) {
      if (entry.value.containsKey(permissionId)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get the human-readable name for a specific permission ID
  String? getPermissionName(String permissionId) {
    for (final modulePerms in _permissions.values) {
      final perm = modulePerms[permissionId];
      if (perm != null) {
        return perm.name;
      }
    }
    return null;
  }
}

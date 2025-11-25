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
    _permissions[moduleId] = {
      for (final perm in permissions) perm.id: perm,
    };
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
}


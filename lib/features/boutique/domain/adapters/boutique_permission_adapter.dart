import 'package:elyf_groupe_app/core/permissions/services/permission_service.dart';

/// Adapter to use centralized permission system for boutique module.
class BoutiquePermissionAdapter {
  BoutiquePermissionAdapter({
    required this.permissionService,
    required this.userId,
  });

  final PermissionService permissionService;
  final String userId;

  static const String moduleId = 'boutique';

  /// Initialize and register permissions
  static void initialize() {
    // Permissions are already registered by PermissionInitializer
    // This method is kept for consistency with other modules
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission(String permissionId) async {
    return await permissionService.hasPermission(
      userId,
      moduleId,
      permissionId,
    );
  }

  /// Check if user has any of the specified permissions
  Future<bool> hasAnyPermission(Set<String> permissionIds) async {
    return await permissionService.hasAnyPermission(
      userId,
      moduleId,
      permissionIds,
    );
  }

  /// Check if user has all specified permissions
  Future<bool> hasAllPermissions(Set<String> permissionIds) async {
    return await permissionService.hasAllPermissions(
      userId,
      moduleId,
      permissionIds,
    );
  }
}

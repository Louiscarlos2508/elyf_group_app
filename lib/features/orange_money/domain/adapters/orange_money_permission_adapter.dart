import 'package:elyf_groupe_app/core/permissions/services/permission_service.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/admin_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';

/// Adapter to use centralized permission system for orange_money module.
class OrangeMoneyPermissionAdapter {
  OrangeMoneyPermissionAdapter({
    required this.permissionService,
    required this.userId,
    required this.adminRepository,
    required this.enterpriseRepository,
  });

  final PermissionService permissionService;
  final String userId;
  final AdminRepository adminRepository;
  final EnterpriseRepository enterpriseRepository;

  static const String moduleId = 'orange_money';

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

  /// Check if user has access to a specific enterprise (including via hierarchy)
  Future<bool> hasAccessToEnterprise(String targetEnterpriseId) async {
    // 1. Direct access check
    final directAccess = await adminRepository.getUserEnterpriseModuleUser(
      userId: userId,
      enterpriseId: targetEnterpriseId,
      moduleId: moduleId,
    );

    if (directAccess != null && directAccess.isActive) {
      return true;
    }

    // 2. Hierarchical access check (via ancestors)
    final targetEnterprise = await enterpriseRepository.getEnterpriseById(targetEnterpriseId);
    
    // If no ancestors, no hierarchical access possible
    if (targetEnterprise == null || targetEnterprise.ancestorIds.isEmpty) {
      return false;
    }

    // Check each ancestor (starting from closest parent)
    for (final ancestorId in targetEnterprise.ancestorIds.reversed) {
      final ancestorAccess = await adminRepository.getUserEnterpriseModuleUser(
        userId: userId,
        enterpriseId: ancestorId,
        moduleId: moduleId,
      );

      if (ancestorAccess != null && 
          ancestorAccess.isActive && 
          ancestorAccess.includesChildren) {
        return true;
      }
    }

    return false;
  }

  /// Get all enterprise IDs accessible by the user (direct + descendants if applicable)
  Future<Set<String>> getAccessibleEnterpriseIds(String rootEnterpriseId) async {
    final canViewNetwork = await hasPermission('view_network_dashboard');
    
    if (!canViewNetwork) {
      return {rootEnterpriseId};
    }

    // Check if user has "includesChildren" access on root enterprise
    final rootAccess = await adminRepository.getUserEnterpriseModuleUser(
      userId: userId,
      enterpriseId: rootEnterpriseId,
      moduleId: moduleId,
    );

    if (rootAccess == null || !rootAccess.isActive || !rootAccess.includesChildren) {
      return {rootEnterpriseId};
    }

    // Fetch all enterprises and filter by ancestor
    // Note: This might be optimized by adding a specific query method in EnterpriseRepository
    final allEnterprises = await enterpriseRepository.getAllEnterprises();
    
    final accessibleIds = allEnterprises
        .where((e) => e.ancestorIds.contains(rootEnterpriseId))
        .map((e) => e.id)
        .toSet();
    
    accessibleIds.add(rootEnterpriseId);
    
    return accessibleIds;
  }
}

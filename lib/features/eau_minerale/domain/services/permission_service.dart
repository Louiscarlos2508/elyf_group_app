import '../entities/module_permission.dart';
import '../entities/eau_minerale_section.dart';

/// Service for checking user permissions in the eau minérale module.
abstract class PermissionService {
  /// Check if the current user has a specific permission.
  bool hasPermission(ModulePermission permission);

  /// Check if the current user has any of the required permissions.
  bool hasAnyPermission(Set<ModulePermission> permissions);

  /// Check if the current user has all required permissions.
  bool hasAllPermissions(Set<ModulePermission> permissions);

  /// Get the current user's role.
  EauMineraleRole? getCurrentRole();

  /// Check if a section is accessible.
  bool canAccessSection(EauMineraleSection section);
}

/// Mock implementation of PermissionService.
class MockPermissionService implements PermissionService {
  MockPermissionService({
    EauMineraleRole? role,
  }) : _role = role ?? EauMineraleRole.responsable;

  final EauMineraleRole _role;
  late final RolePermissions _rolePermissions = RolePermissions(
    role: _role,
    permissions: RolePermissions.defaultPermissions[_role] ?? {},
  );

  @override
  bool hasPermission(ModulePermission permission) {
    return _rolePermissions.hasPermission(permission);
  }

  @override
  bool hasAnyPermission(Set<ModulePermission> permissions) {
    return _rolePermissions.hasAnyPermission(permissions);
  }

  @override
  bool hasAllPermissions(Set<ModulePermission> permissions) {
    return _rolePermissions.hasAllPermissions(permissions);
  }

  @override
  EauMineraleRole? getCurrentRole() {
    return _role;
  }

  @override
  bool canAccessSection(EauMineraleSection section) {
    switch (section) {
      case EauMineraleSection.activity:
        return hasPermission(ModulePermission.viewDashboard);
      case EauMineraleSection.production:
        return hasPermission(ModulePermission.viewProduction);
      case EauMineraleSection.sales:
        return hasPermission(ModulePermission.viewSales);
      case EauMineraleSection.stock:
        return hasPermission(ModulePermission.viewStock);
      case EauMineraleSection.clients:
        return hasPermission(ModulePermission.viewCredits);
      case EauMineraleSection.finances:
        return hasPermission(ModulePermission.viewFinances);
      case EauMineraleSection.salaries:
        return hasPermission(ModulePermission.viewSalaries);
      case EauMineraleSection.reports:
        return hasPermission(ModulePermission.viewReports);
      case EauMineraleSection.profile:
        return hasPermission(ModulePermission.viewProfile);
      case EauMineraleSection.settings:
        return hasPermission(ModulePermission.viewSettings);
    }
  }
}


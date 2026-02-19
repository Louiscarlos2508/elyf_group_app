import 'package:elyf_groupe_app/core/permissions/services/permission_service.dart';
import 'package:elyf_groupe_app/core/permissions/services/permission_registry.dart';
import '../../../../core/permissions/modules/eau_minerale_permissions.dart';
import '../../domain/entities/eau_minerale_section.dart';

/// Adapter to use centralized permission system for eau_minerale module.
class EauMineralePermissionAdapter {
  EauMineralePermissionAdapter({
    required this.permissionService,
    required this.userId,
  });

  final PermissionService permissionService;
  final String userId;

  static const String moduleId = 'eau_minerale';

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

  /// Check if user can access a section
  Future<bool> canAccessSection(EauMineraleSection section) async {
    switch (section) {
      case EauMineraleSection.activity:
        return hasPermission(EauMineralePermissions.viewDashboard.id);
      case EauMineraleSection.production:
        return hasPermission(EauMineralePermissions.viewProduction.id);
      case EauMineraleSection.sales:
        return hasPermission(EauMineralePermissions.viewSales.id);
      case EauMineraleSection.stock:
        return hasPermission(EauMineralePermissions.viewStock.id);
      case EauMineraleSection.clients:
        return hasPermission(EauMineralePermissions.viewCredits.id);
      case EauMineraleSection.suppliers:
        return hasPermission(EauMineralePermissions.viewSuppliers.id);
      case EauMineraleSection.purchases:
        return hasPermission(EauMineralePermissions.viewPurchases.id);
      case EauMineraleSection.finances:
        return await hasPermission(EauMineralePermissions.viewFinances.id);
      case EauMineraleSection.treasury:
        return await hasPermission(EauMineralePermissions.viewTreasury.id);
      case EauMineraleSection.salaries:
        return hasPermission(EauMineralePermissions.viewSalaries.id);
      case EauMineraleSection.reports:
        return hasPermission(EauMineralePermissions.viewReports.id);
      case EauMineraleSection.profile:
        return hasPermission(EauMineralePermissions.viewProfile.id);
      case EauMineraleSection.settings:
        return hasPermission(EauMineralePermissions.viewSettings.id);
      case EauMineraleSection.catalog:
        return hasPermission(EauMineralePermissions.manageProducts.id);
    }
  }
}

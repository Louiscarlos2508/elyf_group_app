import '../../../../features/administration/domain/repositories/admin_repository.dart';
import '../../logging/app_logger.dart';
import '../../permissions/entities/module_user.dart';
import '../../permissions/entities/user_role.dart';
import '../../permissions/services/permission_service.dart';
import '../entities/enterprise_module_user.dart';

/// Implémentation unifiée de PermissionService utilisant Firestore/Drift via AdminController.
///
/// Ce service centralise la logique de permission multi-tenant pour toute l'application.
class FirestorePermissionService implements PermissionService {
  FirestorePermissionService({
    required this.adminRepository,
    required this.getActiveEnterpriseId,
  });

  final AdminRepository adminRepository;
  final String? Function() getActiveEnterpriseId;

  @override
  Future<bool> hasPermission(
    String userId,
    String moduleId,
    String permissionId, {
    String? enterpriseId,
  }) async {
    try {
      final effectiveEnterpriseId = enterpriseId ?? getActiveEnterpriseId();
      if (effectiveEnterpriseId == null) return false;

      final access = await getEnterpriseModuleUser(
        userId,
        effectiveEnterpriseId,
        moduleId,
      );

      if (access == null || !access.isActive) return false;

      // Check wildcard and roles
      final roles = await adminRepository.getAllRoles();
      for (final roleId in access.roleIds) {
        final role = roles.firstWhere((r) => r.id == roleId);
        if (role.hasPermission('*') || role.hasPermission(permissionId)) {
          return true;
        }
      }

      // Check custom permissions
      return access.customPermissions.contains(permissionId);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Error checking permission: $permissionId',
        name: 'FirestorePermissionService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<UserRole?> getUserRole(
    String userId,
    String moduleId, {
    String? enterpriseId,
  }) async {
    final access = await getEnterpriseModuleUser(
      userId,
      enterpriseId ?? getActiveEnterpriseId() ?? '',
      moduleId,
    );
    if (access == null || access.roleIds.isEmpty) return null;

    final roles = await adminRepository.getAllRoles();
    try {
      return roles.firstWhere((r) => r.id == access.roleIds.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ModuleUser?> getModuleUser(
    String userId,
    String moduleId, {
    String? enterpriseId,
  }) async {
    final access = await getEnterpriseModuleUser(
      userId,
      enterpriseId ?? getActiveEnterpriseId() ?? '',
      moduleId,
    );
    if (access == null) return null;

    return ModuleUser(
      userId: access.userId,
      moduleId: access.moduleId,
      roleId: access.roleId,
      customPermissions: access.customPermissions,
      isActive: access.isActive,
      createdAt: access.createdAt,
      updatedAt: access.updatedAt,
    );
  }

  @override
  Future<Set<String>> getUserPermissions(
    String userId,
    String moduleId, {
    String? enterpriseId,
  }) async {
    final access = await getEnterpriseModuleUser(
      userId,
      enterpriseId ?? getActiveEnterpriseId() ?? '',
      moduleId,
    );
    if (access == null) return {};

    final permissions = <String>{...access.customPermissions};
    final roles = await adminRepository.getAllRoles();

    for (final roleId in access.roleIds) {
      final role = roles.firstWhere((r) => r.id == roleId);
      permissions.addAll(role.permissions);
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
      if (await hasPermission(userId, moduleId, permissionId,
          enterpriseId: enterpriseId)) {
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
      if (!await hasPermission(userId, moduleId, permissionId,
          enterpriseId: enterpriseId)) {
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
    try {
      final accesses = await adminRepository
          .getEnterpriseModuleUsersByEnterpriseAndModule(
        enterpriseId,
        moduleId,
      );

      return accesses.firstWhere(
        (a) => a.userId == userId && a.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<EnterpriseModuleUser>> getUserAccesses(String userId) async {
    try {
      return await adminRepository.getUserEnterpriseModuleUsers(userId);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<String>> getUserEnterprises(String userId) async {
    final accesses = await getUserAccesses(userId);
    return accesses.map((a) => a.enterpriseId).toSet().toList();
  }

  @override
  Future<List<String>> getUserModules(
    String userId,
    String enterpriseId,
  ) async {
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

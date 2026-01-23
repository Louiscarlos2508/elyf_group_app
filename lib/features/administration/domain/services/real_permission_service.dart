import 'dart:developer' as developer;

import '../../../../core/permissions/services/permission_service.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/permissions/entities/module_user.dart';
import '../../application/controllers/admin_controller.dart';

/// Exception pour indiquer qu'aucun accès n'a été trouvé
class _NoAccessException implements Exception {}

/// Implémentation réelle de PermissionService qui utilise les données Firestore.
///
/// Récupère les permissions via AdminController (qui lit depuis Drift offline-first).
/// Prend en compte l'entreprise active pour le multi-tenant.
///
/// Respecte l'architecture Clean Architecture en utilisant le controller
/// au lieu d'accéder directement au repository.
class RealPermissionService implements PermissionService {
  RealPermissionService({
    required this.adminController,
    required this.getActiveEnterpriseId,
  });

  final AdminController adminController;
  final String? Function() getActiveEnterpriseId;

  @override
  Future<bool> hasPermission(
    String userId,
    String moduleId,
    String permissionId,
  ) async {
    try {
      // Récupérer l'entreprise active
      final enterpriseId = getActiveEnterpriseId();
      if (enterpriseId == null) {
        developer.log(
          'hasPermission: enterpriseId is null',
          name: 'RealPermissionService',
        );
        return false;
      }

      // Récupérer l'accès EnterpriseModuleUser pour cet utilisateur, entreprise et module
      final accesses = await adminController
          .getEnterpriseModuleUsersByEnterpriseAndModule(
            enterpriseId,
            moduleId,
          );

      final access = accesses.firstWhere(
        (a) => a.userId == userId && a.isActive,
        orElse: () => throw _NoAccessException(),
      );

      if (!access.isActive) {
        developer.log(
          'hasPermission: access is not active for userId=$userId, moduleId=$moduleId',
          name: 'RealPermissionService',
        );
        return false;
      }

      // Récupérer le rôle
      final roles = await adminController.getAllRoles();
      final role = roles.firstWhere(
        (r) => r.id == access.roleId,
        orElse: () => throw Exception('Role not found: ${access.roleId}'),
      );

      // Vérifier si le rôle a la permission wildcard
      if (role.hasPermission('*')) {
        developer.log(
          'hasPermission: role ${role.id} has wildcard permission (*) - granting access to $permissionId',
          name: 'RealPermissionService',
        );
        return true;
      }

      // Vérifier les permissions du rôle
      final roleHasPermission = role.hasPermission(permissionId);
      if (roleHasPermission) {
        developer.log(
          'hasPermission: role ${role.id} has permission $permissionId',
          name: 'RealPermissionService',
        );
        return true;
      }

      // Vérifier les permissions personnalisées
      final hasCustomPermission = access.customPermissions.contains(permissionId);
      developer.log(
        'hasPermission: userId=$userId, moduleId=$moduleId, permissionId=$permissionId, '
        'roleId=${role.id}, rolePermissions=${role.permissions}, '
        'customPermissions=${access.customPermissions}, '
        'result=$hasCustomPermission',
        name: 'RealPermissionService',
      );
      return hasCustomPermission;
    } on _NoAccessException {
      developer.log(
        'hasPermission: NoAccessException for userId=$userId, moduleId=$moduleId, permissionId=$permissionId',
        name: 'RealPermissionService',
      );
      return false;
    } catch (e) {
      developer.log(
        'hasPermission: Error checking permission - userId=$userId, moduleId=$moduleId, permissionId=$permissionId, error=$e',
        name: 'RealPermissionService',
        error: e,
      );
      // En cas d'erreur, retourner false (fail-safe)
      return false;
    }
  }

  @override
  Future<UserRole?> getUserRole(String userId, String moduleId) async {
    try {
      final enterpriseId = getActiveEnterpriseId();
      if (enterpriseId == null) {
        return null;
      }

      final accesses = await adminController
          .getEnterpriseModuleUsersByEnterpriseAndModule(
            enterpriseId,
            moduleId,
          );

      final access = accesses.firstWhere(
        (a) => a.userId == userId && a.isActive,
        orElse: () => throw _NoAccessException(),
      );

      final roles = await adminController.getAllRoles();
      return roles.firstWhere(
        (r) => r.id == access.roleId,
        orElse: () => throw Exception('Role not found: ${access.roleId}'),
      );
    } on _NoAccessException {
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ModuleUser?> getModuleUser(String userId, String moduleId) async {
    try {
      final enterpriseId = getActiveEnterpriseId();
      if (enterpriseId == null) {
        return null;
      }

      final accesses = await adminController
          .getEnterpriseModuleUsersByEnterpriseAndModule(
            enterpriseId,
            moduleId,
          );

      final access = accesses.firstWhere(
        (a) => a.userId == userId,
        orElse: () => throw _NoAccessException(),
      );

      // Convertir EnterpriseModuleUser en ModuleUser pour compatibilité
      return ModuleUser(
        userId: access.userId,
        moduleId: access.moduleId,
        roleId: access.roleId,
        customPermissions: access.customPermissions,
        isActive: access.isActive,
        createdAt: access.createdAt,
        updatedAt: access.updatedAt,
      );
    } on _NoAccessException {
      return null;
    } catch (e) {
      return null;
    }
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

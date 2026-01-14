import '../../../../../core/permissions/services/permission_service.dart';
import '../../../../../core/auth/providers.dart'
    show currentUserProvider, authServiceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;

/// Service for validating permissions before performing actions.
///
/// Ensures users have the required permissions before allowing actions.
/// System admins (isAdmin: true) bypass all permission checks.
class PermissionValidatorService {
  PermissionValidatorService({required this.permissionService, this.ref});

  final PermissionService permissionService;
  final Ref? ref;

  /// Check if user is system admin
  ///
  /// Vérifie si l'utilisateur est admin en consultant directement AuthService
  /// pour éviter les problèmes avec currentUserProvider qui peut ne pas être prêt.
  Future<bool> _isSystemAdmin(String userId) async {
    if (ref == null) return false;

    try {
      // Essayer d'accéder directement à AuthService pour éviter les problèmes
      // avec currentUserProvider qui peut ne pas être prêt pendant la connexion
      try {
        final authService = ref!.read(authServiceProvider);

        // S'assurer que le service est initialisé
        if (!authService.isAuthenticated) {
          // Si l'utilisateur n'est pas authentifié, essayer d'initialiser
          await authService.initialize();
        }

        final currentUser = authService.currentUser;
        if (currentUser?.id == userId && currentUser?.isAdmin == true) {
          return true;
        }
      } catch (e) {
        // Si AuthService n'est pas disponible ou non initialisé, essayer avec currentUserProvider
        // mais de manière sécurisée avec un timeout
        try {
          final currentUser = await ref!
              .read(currentUserProvider.future)
              .timeout(const Duration(seconds: 2));
          if (currentUser?.id == userId && currentUser?.isAdmin == true) {
            return true;
          }
        } catch (e) {
          // Si les deux méthodes échouent, retourner false (fail-safe)
          return false;
        }
      }

      // Si ce n'est pas l'utilisateur actuel ou pas admin, retourner false
      return false;
    } catch (e) {
      // En cas d'erreur, retourner false (fail-safe)
      return false;
    }
  }

  /// Check if user has permission to perform an action
  /// System admins (isAdmin: true) have all permissions automatically
  Future<bool> hasPermission({
    required String userId,
    required String moduleId,
    required String permissionId,
  }) async {
    // System admins have all permissions
    if (await _isSystemAdmin(userId)) {
      return true;
    }
    return await permissionService.hasPermission(
      userId,
      moduleId,
      permissionId,
    );
  }

  /// Check if user has any of the required permissions
  Future<bool> hasAnyPermission({
    required String userId,
    required String moduleId,
    required Set<String> permissionIds,
  }) async {
    return await permissionService.hasAnyPermission(
      userId,
      moduleId,
      permissionIds,
    );
  }

  /// Check if user has all required permissions
  Future<bool> hasAllPermissions({
    required String userId,
    required String moduleId,
    required Set<String> permissionIds,
  }) async {
    return await permissionService.hasAllPermissions(
      userId,
      moduleId,
      permissionIds,
    );
  }

  /// Check if user has admin permission for a module
  Future<bool> isModuleAdmin({
    required String userId,
    required String moduleId,
  }) async {
    return await hasPermission(
      userId: userId,
      moduleId: moduleId,
      permissionId: '*',
    );
  }

  /// Check if user can create entities in a module
  Future<bool> canCreate({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
          userId: userId,
          moduleId: moduleId,
          permissionId: 'create_$entityType',
        ) ||
        await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Check if user can update entities in a module
  Future<bool> canUpdate({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
          userId: userId,
          moduleId: moduleId,
          permissionId: 'update_$entityType',
        ) ||
        await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Check if user can delete entities in a module
  Future<bool> canDelete({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
          userId: userId,
          moduleId: moduleId,
          permissionId: 'delete_$entityType',
        ) ||
        await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Check if user can view entities in a module
  Future<bool> canView({
    required String userId,
    required String moduleId,
    required String entityType,
  }) async {
    return await hasPermission(
          userId: userId,
          moduleId: moduleId,
          permissionId: 'view_$entityType',
        ) ||
        await isModuleAdmin(userId: userId, moduleId: moduleId);
  }

  /// Validate admin permissions
  ///
  /// Admin-specific permissions for administration module
  /// System admins (isAdmin: true) can manage everything
  Future<bool> canManageUsers({required String userId}) async {
    // System admins can manage users
    if (await _isSystemAdmin(userId)) {
      return true;
    }
    return await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'create_user',
        ) ||
        await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'edit_user',
        ) ||
        await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'delete_user',
        );
  }

  Future<bool> canManageRoles({required String userId}) async {
    // System admins can manage roles
    if (await _isSystemAdmin(userId)) {
      return true;
    }
    return await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'create_role',
        ) ||
        await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'edit_role',
        ) ||
        await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'delete_role',
        );
  }

  Future<bool> canManageEnterprises({required String userId}) async {
    // System admins can manage enterprises
    if (await _isSystemAdmin(userId)) {
      return true;
    }
    return await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'create_enterprise',
        ) ||
        await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'edit_enterprise',
        ) ||
        await hasPermission(
          userId: userId,
          moduleId: 'administration',
          permissionId: 'delete_enterprise',
        );
  }
}


import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/audit/audit_service.dart';
import '../../domain/entities/audit_log.dart';
import '../../data/services/firestore_sync_service.dart';
import '../../domain/services/validation/permission_validator_service.dart';

/// Controller pour gérer les rôles.
///
/// Intègre audit trail, Firestore sync et validation des permissions pour les rôles.
class RoleController {
  RoleController(
    this._repository, {
    this.auditService,
    this.firestoreSync,
    this.permissionValidator,
    this.userRepository,
  });

  final AdminRepository _repository;
  final AuditService? auditService;
  final FirestoreSyncService? firestoreSync;
  final PermissionValidatorService? permissionValidator;
  final UserRepository? userRepository;

  /// Helper method to get user display name for audit logs
  Future<String?> _getUserDisplayName(String? userId) async {
    if (userId == null || userId == 'system' || userRepository == null) {
      return null;
    }
    try {
      final user = await userRepository!.getUserById(userId);
      return user?.fullName;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error fetching user display name for audit log: ${appException.message}',
        name: 'role.controller',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Récupère tous les rôles.
  ///
  /// Lit UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée.
  /// La synchronisation avec Firestore est gérée par le RealtimeSyncService.
  Future<List<UserRole>> getAllRoles() async {
    try {
      // Lire UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée
      // La synchronisation avec Firestore est gérée par le RealtimeSyncService
      final localRoles = await _repository.getAllRoles();

      // Dédupliquer les rôles par ID pour éviter les duplications
      // (peut arriver si la synchronisation crée des doublons dans Drift)
      final uniqueRoles = <String, UserRole>{};
      for (final role in localRoles) {
        // Garder le premier rôle trouvé avec chaque ID
        if (!uniqueRoles.containsKey(role.id)) {
          uniqueRoles[role.id] = role;
        }
      }

      return uniqueRoles.values.toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error getting all roles from local database: ${appException.message}',
        name: 'role.controller',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Récupère les rôles pour un module spécifique.
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    return await _repository.getModuleRoles(moduleId);
  }

  /// Crée un nouveau rôle.
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before creating.
  ///
  /// Throws an exception with a user-friendly message if:
  /// - User doesn't have permission to create roles
  /// - Firestore sync fails (e.g., permission denied)
  Future<void> createRole(UserRole role, {String? currentUserId}) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageRoles(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission refusée : Vous n\'avez pas les droits pour créer des rôles. '
          'Contactez un administrateur pour obtenir les permissions nécessaires.',
          'PERMISSION_DENIED',
        );
      }
    }

    try {
      await _repository.createRole(role);

      // Sync to Firestore - cette opération peut échouer avec une exception
      if (firestoreSync != null) {
        await firestoreSync!.syncRoleToFirestore(role);
      }

      // Récupérer le nom de l'utilisateur pour l'audit trail
      final userDisplayName = await _getUserDisplayName(currentUserId);

      // Log audit trail
      auditService?.logAction(
        action: AuditAction.create,
        entityType: 'role',
        entityId: role.id,
        userId: currentUserId ?? 'system',
        description: 'Role created: ${role.name}',
        newValue: {
          'id': role.id,
          'name': role.name,
          'description': role.description,
          'permissions': role.permissions.toList(),
          'isSystemRole': role.isSystemRole,
        },
        userDisplayName: userDisplayName,
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de la création du rôle: ${appException.message}',
        name: 'role.controller',
        error: e,
        stackTrace: stackTrace,
      );
      // Si c'est déjà une AppException, la propager
      if (e is AppException) {
        rethrow;
      }
      // Sinon, envelopper dans une exception avec message clair
      throw UnknownException(
        'Erreur lors de la création du rôle: ${appException.message}',
        'ROLE_CREATION_ERROR',
      );
    }
  }

  /// Met à jour un rôle existant.
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before updating.
  ///
  /// Throws an exception with a user-friendly message if:
  /// - User doesn't have permission to update roles
  /// - Role not found
  /// - Firestore sync fails (e.g., permission denied)
  Future<void> updateRole(
    UserRole role, {
    String? currentUserId,
    UserRole? oldRole,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageRoles(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission refusée : Vous n\'avez pas les droits pour modifier des rôles. '
          'Contactez un administrateur pour obtenir les permissions nécessaires.',
          'PERMISSION_DENIED',
        );
      }
    }

    try {
      // Get old role if not provided
      final oldRoleData =
          oldRole ??
          (await _repository.getModuleRoles(role.id)).firstWhere(
            (r) => r.id == role.id,
            orElse: () => throw NotFoundException(
              'Rôle non trouvé: ${role.id}',
              'ROLE_NOT_FOUND',
            ),
          );

      await _repository.updateRole(role);

      // Sync to Firestore - cette opération peut échouer avec une exception
      if (firestoreSync != null) {
        await firestoreSync!.syncRoleToFirestore(role, isUpdate: true);
      }

      // Récupérer le nom de l'utilisateur pour l'audit trail
      final userDisplayName = await _getUserDisplayName(currentUserId);

      // Log audit trail
      auditService?.logAction(
        action: AuditAction.update,
        entityType: 'role',
        entityId: role.id,
        userId: currentUserId ?? 'system',
        description: 'Role updated: ${role.name}',
        oldValue: {
          'id': oldRoleData.id,
          'name': oldRoleData.name,
          'description': oldRoleData.description,
          'permissions': oldRoleData.permissions.toList(),
          'isSystemRole': oldRoleData.isSystemRole,
        },
        newValue: {
          'id': role.id,
          'name': role.name,
          'description': role.description,
          'permissions': role.permissions.toList(),
          'isSystemRole': role.isSystemRole,
        },
        userDisplayName: userDisplayName,
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de la modification du rôle: ${appException.message}',
        name: 'role.controller',
        error: e,
        stackTrace: stackTrace,
      );
      // Si c'est déjà une AppException, la propager
      if (e is AppException) {
        rethrow;
      }
      // Sinon, envelopper dans une exception avec message clair
      throw UnknownException(
        'Erreur lors de la modification du rôle: ${appException.message}',
        'ROLE_UPDATE_ERROR',
      );
    }
  }

  /// Supprime un rôle (si ce n'est pas un rôle système).
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before deleting.
  ///
  /// Throws an exception with a user-friendly message if:
  /// - User doesn't have permission to delete roles
  /// - Role not found
  /// - Firestore deletion fails
  Future<void> deleteRole(
    String roleId, {
    String? currentUserId,
    UserRole? roleData,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageRoles(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission refusée : Vous n\'avez pas les droits pour supprimer des rôles. '
          'Contactez un administrateur pour obtenir les permissions nécessaires.',
          'PERMISSION_DENIED',
        );
      }
    }

    try {
      // Get role data if not provided
      final role =
          roleData ??
          (await _repository.getAllRoles()).firstWhere(
            (r) => r.id == roleId,
            orElse: () => throw NotFoundException(
              'Rôle non trouvé: $roleId',
              'ROLE_NOT_FOUND',
            ),
          );

      // Delete from repository (this will queue sync to Firestore automatically)
      // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
      // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.
      await _repository.deleteRole(roleId);

      // Récupérer le nom de l'utilisateur pour l'audit trail
      final userDisplayName = await _getUserDisplayName(currentUserId);

      // Log audit trail
      auditService?.logAction(
        action: AuditAction.delete,
        entityType: 'role',
        entityId: roleId,
        userId: currentUserId ?? 'system',
        description: 'Role deleted: ${role.name}',
        oldValue: {
          'id': role.id,
          'name': role.name,
          'description': role.description,
          'permissions': role.permissions.toList(),
          'isSystemRole': role.isSystemRole,
        },
        userDisplayName: userDisplayName,
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de la suppression du rôle: ${appException.message}',
        name: 'role.controller',
        error: e,
        stackTrace: stackTrace,
      );
      // Si c'est déjà une AppException, la propager
      if (e is AppException) {
        rethrow;
      }
      // Sinon, envelopper dans une exception avec message clair
      throw UnknownException(
        'Erreur lors de la suppression du rôle: ${appException.message}',
        'ROLE_DELETE_ERROR',
      );
    }
  }

  /// Surveille tous les rôles (Stream).
  Stream<List<UserRole>> watchAllRoles() {
    return _repository.watchAllRoles();
  }

  /// Surveille le statut de synchronisation (Stream).
  Stream<bool> watchSyncStatus() {
    return _repository.watchSyncStatus();
  }
}

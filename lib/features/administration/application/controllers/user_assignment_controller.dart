import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/entities/enterprise.dart';
import '../../domain/services/audit/audit_service.dart';
import '../../domain/entities/audit_log.dart';
import '../../data/services/firestore_sync_service.dart';
import '../../domain/services/validation/permission_validator_service.dart';

/// Controller pour gérer les assignations d'utilisateurs aux entreprises et modules.
///
/// Intègre audit trail, Firestore sync et validation des permissions pour les assignations.
class UserAssignmentController {
  UserAssignmentController(
    this._repository, {
    this.auditService,
    this.firestoreSync,
    this.permissionValidator,
    this.userRepository,
    this.enterpriseRepository,
  });

  final AdminRepository _repository;
  final AuditService? auditService;
  final FirestoreSyncService? firestoreSync;
  final PermissionValidatorService? permissionValidator;
  final UserRepository? userRepository;
  final EnterpriseRepository? enterpriseRepository;

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
        name: 'user.assignment.controller',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Récupère tous les accès EnterpriseModuleUser.
  ///
  /// Lit UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée.
  /// La synchronisation avec Firestore est gérée par le RealtimeSyncService.
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() async {
    try {
      final localAssignments = await _repository.getEnterpriseModuleUsers();
      return localAssignments;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error getting EnterpriseModuleUsers from local database: ${appException.message}',
        name: 'user.assignment.controller',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Récupère les accès d'un utilisateur spécifique.
  Future<List<EnterpriseModuleUser>> getUserEnterpriseModuleUsers(
    String userId,
  ) async {
    return await _repository.getUserEnterpriseModuleUsers(userId);
  }

  /// Récupère les utilisateurs d'une entreprise.
  Future<List<EnterpriseModuleUser>> getEnterpriseUsers(
    String enterpriseId,
  ) async {
    return await _repository.getEnterpriseUsers(enterpriseId);
  }

  /// Récupère les accès pour une entreprise et un module spécifiques.
  Future<List<EnterpriseModuleUser>>
  getEnterpriseModuleUsersByEnterpriseAndModule(
    String enterpriseId,
    String moduleId,
  ) async {
    return await _repository.getEnterpriseModuleUsersByEnterpriseAndModule(
      enterpriseId,
      moduleId,
    );
  }

  /// Assigne un utilisateur à une entreprise et un module avec un rôle.
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before assigning.
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser, {
    String? currentUserId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageUsers(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission denied: Cannot assign users',
          'PERMISSION_DENIED',
        );
      }
    }
    await _repository.assignUserToEnterprise(enterpriseModuleUser);

    // Sync is now handled by the repository via SyncManager queue (background)

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.assign,
      entityType: 'enterprise_module_user',
      entityId: enterpriseModuleUser.documentId,
      userId: currentUserId ?? 'system',
      description: 'User assigned to enterprise and module',
      newValue: enterpriseModuleUser.toMap(),
      moduleId: enterpriseModuleUser.moduleId,
      enterpriseId: enterpriseModuleUser.enterpriseId,
      userDisplayName: userDisplayName,
    );
  }

  /// Assigne un utilisateur à plusieurs entreprises avec le même module et rôle.
  ///
  /// Crée plusieurs EnterpriseModuleUser en une seule opération.
  /// Logs audit trail and syncs to Firestore pour chaque assignation.
  /// Validates permissions before assigning.
  Future<void> batchAssignUserToEnterprises({
    required String userId,
    required List<String> enterpriseIds,
    required String moduleId,
    required List<String> roleIds,
    required bool isActive,
    String? currentUserId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageUsers(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission denied: Cannot assign users',
          'PERMISSION_DENIED',
        );
      }
    }

    if (enterpriseIds.isEmpty) {
      throw ValidationException(
        'At least one enterprise must be selected',
        'NO_ENTERPRISE_SELECTED',
      );
    }

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);
    final now = DateTime.now();

    // Créer toutes les assignations
    final assignments = <EnterpriseModuleUser>[];
    for (final enterpriseId in enterpriseIds) {
      String? parentId;
      if (enterpriseRepository != null) {
        final ent = await enterpriseRepository!.getEnterpriseById(enterpriseId);
        parentId = ent?.parentEnterpriseId;
      }

      assignments.add(EnterpriseModuleUser(
        userId: userId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        roleIds: roleIds,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
        parentEnterpriseId: parentId,
      ));
    }

    // Assigner toutes les entreprises
    for (final assignment in assignments) {
      await _repository.assignUserToEnterprise(assignment);

      // Sync is now handled by the repository via SyncManager queue (background)

      // Log audit trail pour chaque assignation
      auditService?.logAction(
        action: AuditAction.assign,
        entityType: 'enterprise_module_user',
        entityId: assignment.documentId,
        userId: currentUserId ?? 'system',
        description: 'User assigned to enterprise and module (batch)',
        newValue: assignment.toMap(),
        moduleId: assignment.moduleId,
        enterpriseId: assignment.enterpriseId,
        userDisplayName: userDisplayName,
      );
    }
  }

  /// Assigne un utilisateur à plusieurs modules et plusieurs entreprises avec le même rôle.
  ///
  /// Crée un EnterpriseModuleUser pour chaque combinaison (module, entreprise).
  /// Ne crée que les combinaisons valides (entreprise.type == module).
  /// Logs audit trail and syncs to Firestore pour chaque assignation.
  /// Validates permissions before assigning.
  Future<void> batchAssignUserToModulesAndEnterprises({
    required String userId,
    required List<String> moduleIds,
    required List<String> enterpriseIds,
    required Map<String, List<String>> roleIdsByModule,
    required bool isActive,
    String? currentUserId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageUsers(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission denied: Cannot assign users',
          'PERMISSION_DENIED',
        );
      }
    }

    if (moduleIds.isEmpty) {
      throw ValidationException(
        'At least one module must be selected',
        'NO_MODULE_SELECTED',
      );
    }

    if (enterpriseIds.isEmpty) {
      throw ValidationException(
        'At least one enterprise must be selected',
        'NO_ENTERPRISE_SELECTED',
      );
    }

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);
    final now = DateTime.now();

    // Mapper module ID vers types d'entreprise compatibles
    List<String> getEnterpriseTypesForModule(String moduleId) {
      final compatibleTypes = <String>{};

      switch (moduleId) {
        case 'gaz':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isGas)
              .map((t) => t.id));
          break;
        case 'eau_minerale':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isWater)
              .map((t) => t.id));
          break;
        case 'orange_money':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isMobileMoney)
              .map((t) => t.id));
          break;
        case 'immobilier':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isRealEstate)
              .map((t) => t.id));
          break;
        case 'boutique':
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.isShop)
              .map((t) => t.id));
          break;
        default:
          compatibleTypes.addAll(EnterpriseType.values
              .where((t) => t.module.id == moduleId)
              .map((t) => t.id));
      }
      return compatibleTypes.toList();
    }

    // Récupérer les entreprises pour valider les types
    final enterprises = enterpriseRepository != null
        ? await enterpriseRepository!.getAllEnterprises()
        : <Enterprise>[];

    // Créer uniquement les assignations valides (entreprise.type == module)
    final assignments = <EnterpriseModuleUser>[];
    for (final moduleId in moduleIds) {
      final expectedEnterpriseTypes = getEnterpriseTypesForModule(moduleId);
      if (expectedEnterpriseTypes.isEmpty) {
        developer.log(
          'Warning: Unknown module type $moduleId or no compatible enterprise types, skipping assignments',
          name: 'user.assignment.controller',
        );
        continue;
      }

      // Récupérer les rôles spécifiques pour ce module
      final moduleRoleIds = roleIdsByModule[moduleId];
      if (moduleRoleIds == null || moduleRoleIds.isEmpty) {
         developer.log(
          'Warning: No roles provided for module $moduleId, skipping assignments for this module',
          name: 'user.assignment.controller',
        );
        continue;
      }

      for (final enterpriseId in enterpriseIds) {
        // Vérifier que le type d'entreprise correspond au module
        final enterprise = enterprises
            .where((e) => e.id == enterpriseId)
            .firstOrNull;

        if (enterprise != null &&
            expectedEnterpriseTypes.contains(enterprise.type.id)) {
          assignments.add(
            EnterpriseModuleUser(
              userId: userId,
              enterpriseId: enterpriseId,
              moduleId: moduleId,
              roleIds: moduleRoleIds, // Utiliser les rôles spécifiques au module
              isActive: isActive,
              createdAt: now,
              updatedAt: now,
              parentEnterpriseId: enterprise.parentEnterpriseId,
            ),
          );
        } else {
          developer.log(
            'Warning: Skipping invalid assignment: enterprise $enterpriseId (type: ${enterprise?.type}) does not match module $moduleId (allowed types: $expectedEnterpriseTypes)',
            name: 'user.assignment.controller',
          );
        }
      }
    }

    if (assignments.isEmpty) {
      throw ValidationException(
        'Aucune assignation valide: toutes les combinaisons entreprise/module sont incompatibles',
        'NO_VALID_ASSIGNMENT',
      );
    }

    // Assigner toutes les combinaisons valides
    for (final assignment in assignments) {
      await _repository.assignUserToEnterprise(assignment);

      // Sync is now handled by the repository via SyncManager queue (background)

      // Log audit trail pour chaque assignation
      auditService?.logAction(
        action: AuditAction.assign,
        entityType: 'enterprise_module_user',
        entityId: assignment.documentId,
        userId: currentUserId ?? 'system',
        description:
            'User assigned to enterprise and module (batch multi-module)',
        newValue: assignment.toMap(),
        moduleId: assignment.moduleId,
        enterpriseId: assignment.enterpriseId,
        userDisplayName: userDisplayName,
      );
    }
  }

  /// Met à jour le rôle d'un utilisateur dans une entreprise et un module.
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before updating.
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    List<String> roleIds, {
    String? currentUserId,
    List<String>? oldRoleIds,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageRoles(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission denied: Cannot update roles',
          'PERMISSION_DENIED',
        );
      }
    }
    await _repository.updateUserRole(userId, enterpriseId, moduleId, roleIds);

    // Get updated assignment for sync
    final assignments = await _repository
        .getEnterpriseModuleUsersByEnterpriseAndModule(enterpriseId, moduleId);
    final assignment = assignments.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw NotFoundException(
        'Assignment not found',
        'ASSIGNMENT_NOT_FOUND',
      ),
    );

    // Sync is now handled by the repository via SyncManager queue (background)

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.roleChange,
      entityType: 'enterprise_module_user',
      entityId: assignment.documentId,
      userId: currentUserId ?? 'system',
      description: 'User roles updated',
      oldValue: oldRoleIds != null ? {'roleIds': oldRoleIds} : null,
      newValue: {'roleIds': roleIds},
      moduleId: moduleId,
      enterpriseId: enterpriseId,
      userDisplayName: userDisplayName,
    );
  }

  /// Met à jour les permissions personnalisées d'un utilisateur.
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before updating.
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions, {
    String? currentUserId,
    Set<String>? oldPermissions,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageUsers(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission denied: Cannot update permissions',
          'PERMISSION_DENIED',
        );
      }
    }
    await _repository.updateUserPermissions(
      userId,
      enterpriseId,
      moduleId,
      permissions,
    );

    // Get updated assignment for sync
    final assignments = await _repository
        .getEnterpriseModuleUsersByEnterpriseAndModule(enterpriseId, moduleId);
    final assignment = assignments.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw NotFoundException(
        'Assignment not found',
        'ASSIGNMENT_NOT_FOUND',
      ),
    );

    // Sync is now handled by the repository via SyncManager queue (background)

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.permissionChange,
      entityType: 'enterprise_module_user',
      entityId: assignment.documentId,
      userId: currentUserId ?? 'system',
      description: 'User permissions updated',
      oldValue: oldPermissions != null
          ? {'permissions': oldPermissions.toList()}
          : null,
      newValue: {'permissions': permissions.toList()},
      moduleId: moduleId,
      enterpriseId: enterpriseId,
      userDisplayName: userDisplayName,
    );
  }

  /// Retire un utilisateur d'une entreprise et d'un module.
  ///
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before removing.
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId, {
    String? currentUserId,
    EnterpriseModuleUser? oldAssignment,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageUsers(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw AuthorizationException(
          'Permission denied: Cannot remove users',
          'PERMISSION_DENIED',
        );
      }
    }
    // Get assignment before deletion if not provided
    final assignment =
        oldAssignment ??
        (await _repository.getEnterpriseModuleUsersByEnterpriseAndModule(
          enterpriseId,
          moduleId,
        )).firstWhere(
          (a) => a.userId == userId,
          orElse: () => throw NotFoundException(
        'Assignment not found',
        'ASSIGNMENT_NOT_FOUND',
      ),
        );

    // La suppression locale et la mise en file d'attente de la sync sont gérées par le repository
    // Le repository utilise syncManager.queueDelete() pour garantir que la suppression sera
    // synchronisée vers Firestore même en cas d'erreur réseau temporaire
    await _repository.removeUserFromEnterprise(userId, enterpriseId, moduleId);
    
    // Note: La suppression dans Firestore est maintenant gérée par le système de synchronisation
    // via syncManager.queueDelete() dans AdminOfflineRepository.removeUserFromEnterprise()
    // Plus besoin d'appeler directement firestoreSync?.deleteFromFirestore() ici

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.unassign,
      entityType: 'enterprise_module_user',
      entityId: assignment.documentId,
      userId: currentUserId ?? 'system',
      description: 'User removed from enterprise and module',
      oldValue: assignment.toMap(),
      moduleId: moduleId,
      enterpriseId: enterpriseId,
      userDisplayName: userDisplayName,
    );
  }

  /// Surveille tous les accès EnterpriseModuleUser (Stream).
  Stream<List<EnterpriseModuleUser>> watchEnterpriseModuleUsers() {
    return _repository.watchEnterpriseModuleUsers();
  }
}

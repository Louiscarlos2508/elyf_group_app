import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/services/audit/audit_service.dart';
import '../../domain/entities/audit_log.dart';
import '../../data/services/firestore_sync_service.dart';
import '../../domain/services/validation/permission_validator_service.dart';

/// Controller pour gérer les opérations d'administration.
/// 
/// Intègre audit trail, Firestore sync et validation des permissions pour les rôles et assignations.
class AdminController {
  AdminController(
    this._repository, {
    this.auditService,
    this.firestoreSync,
    this.permissionValidator,
  });

  final AdminRepository _repository;
  final AuditService? auditService;
  final FirestoreSyncService? firestoreSync;
  final PermissionValidatorService? permissionValidator;

  /// Récupère tous les accès EnterpriseModuleUser.
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() async {
    return await _repository.getEnterpriseModuleUsers();
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
        throw Exception('Permission denied: Cannot assign users');
      }
    }
    await _repository.assignUserToEnterprise(enterpriseModuleUser);

    // Sync to Firestore
    firestoreSync?.syncEnterpriseModuleUserToFirestore(enterpriseModuleUser);

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
    );
  }

  /// Met à jour le rôle d'un utilisateur dans une entreprise et un module.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before updating.
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    String roleId, {
    String? currentUserId,
    String? oldRoleId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageRoles(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw Exception('Permission denied: Cannot update roles');
      }
    }
    await _repository.updateUserRole(
      userId,
      enterpriseId,
      moduleId,
      roleId,
    );

    // Get updated assignment for sync
    final assignments = await _repository
        .getEnterpriseModuleUsersByEnterpriseAndModule(
      enterpriseId,
      moduleId,
    );
    final assignment = assignments.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw Exception('Assignment not found'),
    );

    // Sync to Firestore
    firestoreSync?.syncEnterpriseModuleUserToFirestore(
      assignment,
      isUpdate: true,
    );

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.roleChange,
      entityType: 'enterprise_module_user',
      entityId: assignment.documentId,
      userId: currentUserId ?? 'system',
      description: 'User role updated',
      oldValue: oldRoleId != null ? {'roleId': oldRoleId} : null,
      newValue: {'roleId': roleId},
      moduleId: moduleId,
      enterpriseId: enterpriseId,
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
        throw Exception('Permission denied: Cannot update permissions');
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
        .getEnterpriseModuleUsersByEnterpriseAndModule(
      enterpriseId,
      moduleId,
    );
    final assignment = assignments.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw Exception('Assignment not found'),
    );

    // Sync to Firestore
    firestoreSync?.syncEnterpriseModuleUserToFirestore(
      assignment,
      isUpdate: true,
    );

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
        throw Exception('Permission denied: Cannot remove users');
      }
    }
    // Get assignment before deletion if not provided
    final assignment = oldAssignment ??
        (await _repository
                .getEnterpriseModuleUsersByEnterpriseAndModule(
              enterpriseId,
              moduleId,
            ))
            .firstWhere(
          (a) => a.userId == userId,
          orElse: () => throw Exception('Assignment not found'),
        );

    await _repository.removeUserFromEnterprise(
      userId,
      enterpriseId,
      moduleId,
    );

    // Delete from Firestore
    firestoreSync?.deleteFromFirestore(
      collection: 'enterprise_module_users',
      documentId: assignment.documentId,
    );

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
    );
  }

  /// Récupère tous les rôles.
  Future<List<UserRole>> getAllRoles() async {
    return await _repository.getAllRoles();
  }

  /// Récupère les rôles pour un module spécifique.
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    return await _repository.getModuleRoles(moduleId);
  }

  /// Crée un nouveau rôle.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before creating.
  Future<void> createRole(
    UserRole role, {
    String? currentUserId,
  }) async {
    // Validate permissions
    if (currentUserId != null && permissionValidator != null) {
      final hasPermission = await permissionValidator!.canManageRoles(
        userId: currentUserId,
      );
      if (!hasPermission) {
        throw Exception('Permission denied: Cannot create roles');
      }
    }
    await _repository.createRole(role);

    // Sync to Firestore
    firestoreSync?.syncRoleToFirestore(role);

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
    );
  }

  /// Met à jour un rôle existant.
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before updating.
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
        throw Exception('Permission denied: Cannot update roles');
      }
    }
    // Get old role if not provided
    final oldRoleData = oldRole ?? (await _repository.getModuleRoles(role.id)).firstWhere(
          (r) => r.id == role.id,
          orElse: () => throw Exception('Role not found'),
        );

    await _repository.updateRole(role);

    // Sync to Firestore
    firestoreSync?.syncRoleToFirestore(role, isUpdate: true);

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
    );
  }

  /// Supprime un rôle (si ce n'est pas un rôle système).
  /// 
  /// Logs audit trail and syncs to Firestore.
  /// Validates permissions before deleting.
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
        throw Exception('Permission denied: Cannot delete roles');
      }
    }
    // Get role data if not provided
    final role = roleData ??
        (await _repository.getAllRoles()).firstWhere(
          (r) => r.id == roleId,
          orElse: () => throw Exception('Role not found'),
        );

    await _repository.deleteRole(roleId);

    // Delete from Firestore
    firestoreSync?.deleteFromFirestore(
      collection: 'roles',
      documentId: roleId,
    );

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
    );
  }
}


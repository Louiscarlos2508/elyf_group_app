import 'dart:developer' as developer;

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
    } catch (e) {
      developer.log(
        'Error fetching user display name for audit log: $e',
        name: 'user.assignment.controller',
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
      developer.log(
        'Error getting EnterpriseModuleUsers from local database: $e',
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
        throw Exception('Permission denied: Cannot assign users');
      }
    }
    await _repository.assignUserToEnterprise(enterpriseModuleUser);

    // Sync to Firestore
    firestoreSync?.syncEnterpriseModuleUserToFirestore(enterpriseModuleUser);

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
    required String roleId,
    required bool isActive,
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

    if (enterpriseIds.isEmpty) {
      throw Exception('At least one enterprise must be selected');
    }

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);
    final now = DateTime.now();

    // Créer toutes les assignations
    final assignments = enterpriseIds.map((enterpriseId) {
      return EnterpriseModuleUser(
        userId: userId,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        roleId: roleId,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // Assigner toutes les entreprises
    for (final assignment in assignments) {
      await _repository.assignUserToEnterprise(assignment);

      // Sync to Firestore
      firestoreSync?.syncEnterpriseModuleUserToFirestore(assignment);

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
    required String roleId,
    required bool isActive,
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

    if (moduleIds.isEmpty) {
      throw Exception('At least one module must be selected');
    }

    if (enterpriseIds.isEmpty) {
      throw Exception('At least one enterprise must be selected');
    }

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);
    final now = DateTime.now();

    // Mapper module ID vers type d'entreprise
    String? getEnterpriseTypeForModule(String moduleId) {
      final moduleToTypeMap = {
        'eau_minerale': 'eau_minerale',
        'gaz': 'gaz',
        'orange_money': 'orange_money',
        'immobilier': 'immobilier',
        'boutique': 'boutique',
      };
      return moduleToTypeMap[moduleId];
    }

    // Récupérer les entreprises pour valider les types
    final enterprises = enterpriseRepository != null
        ? await enterpriseRepository!.getAllEnterprises()
        : <Enterprise>[];

    // Créer uniquement les assignations valides (entreprise.type == module)
    final assignments = <EnterpriseModuleUser>[];
    for (final moduleId in moduleIds) {
      final expectedEnterpriseType = getEnterpriseTypeForModule(moduleId);
      if (expectedEnterpriseType == null) {
        developer.log(
          'Warning: Unknown module type $moduleId, skipping assignments',
          name: 'user.assignment.controller',
        );
        continue;
      }

      for (final enterpriseId in enterpriseIds) {
        // Vérifier que le type d'entreprise correspond au module
        final enterprise = enterprises
            .where((e) => e.id == enterpriseId)
            .firstOrNull;

        if (enterprise != null && enterprise.type == expectedEnterpriseType) {
          assignments.add(
            EnterpriseModuleUser(
              userId: userId,
              enterpriseId: enterpriseId,
              moduleId: moduleId,
              roleId: roleId,
              isActive: isActive,
              createdAt: now,
              updatedAt: now,
            ),
          );
        } else {
          developer.log(
            'Warning: Skipping invalid assignment: enterprise $enterpriseId (type: ${enterprise?.type}) does not match module $moduleId (expected type: $expectedEnterpriseType)',
            name: 'user.assignment.controller',
          );
        }
      }
    }

    if (assignments.isEmpty) {
      throw Exception(
        'Aucune assignation valide: toutes les combinaisons entreprise/module sont incompatibles',
      );
    }

    // Assigner toutes les combinaisons valides
    for (final assignment in assignments) {
      await _repository.assignUserToEnterprise(assignment);

      // Sync to Firestore
      firestoreSync?.syncEnterpriseModuleUserToFirestore(assignment);

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
    await _repository.updateUserRole(userId, enterpriseId, moduleId, roleId);

    // Get updated assignment for sync
    final assignments = await _repository
        .getEnterpriseModuleUsersByEnterpriseAndModule(enterpriseId, moduleId);
    final assignment = assignments.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw Exception('Assignment not found'),
    );

    // Sync to Firestore
    firestoreSync?.syncEnterpriseModuleUserToFirestore(
      assignment,
      isUpdate: true,
    );

    // Récupérer le nom de l'utilisateur pour l'audit trail
    final userDisplayName = await _getUserDisplayName(currentUserId);

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
        .getEnterpriseModuleUsersByEnterpriseAndModule(enterpriseId, moduleId);
    final assignment = assignments.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw Exception('Assignment not found'),
    );

    // Sync to Firestore
    firestoreSync?.syncEnterpriseModuleUserToFirestore(
      assignment,
      isUpdate: true,
    );

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
        throw Exception('Permission denied: Cannot remove users');
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
          orElse: () => throw Exception('Assignment not found'),
        );

    await _repository.removeUserFromEnterprise(userId, enterpriseId, moduleId);

    // Delete from Firestore
    firestoreSync?.deleteFromFirestore(
      collection: 'enterprise_module_users',
      documentId: assignment.documentId,
    );

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
}

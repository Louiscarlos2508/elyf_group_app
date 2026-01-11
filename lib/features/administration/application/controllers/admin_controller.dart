import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/user_repository.dart';
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
    } catch (e) {
      developer.log(
        'Error fetching user display name for audit log: $e',
        name: 'admin.controller',
      );
      return null;
    }
  }

  /// Récupère tous les accès EnterpriseModuleUser.
  /// 
  /// Si la base locale est vide, récupère automatiquement depuis Firestore
  /// et sauvegarde localement pour la prochaine fois.
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() async {
    try {
      final localAssignments = await _repository.getEnterpriseModuleUsers();
      
      // Si la base locale contient des assignations, les retourner
      if (localAssignments.isNotEmpty) {
        return localAssignments;
      }
      
      // Si la base locale est vide, essayer de récupérer depuis Firestore
      // et sauvegarder localement pour la prochaine fois
      if (firestoreSync != null) {
        try {
          final firestoreAssignments = await firestoreSync!.pullEnterpriseModuleUsersFromFirestore();
          
          // Sauvegarder chaque assignation dans la base locale SANS déclencher de sync
          // (ces assignations viennent déjà de Firestore, pas besoin de les re-synchroniser)
          for (final assignment in firestoreAssignments) {
            try {
              // Utiliser directement saveToLocal pour éviter de mettre dans la queue de sync
              // Les assignations viennent déjà de Firestore, donc pas besoin de les re-sync
              await (_repository as dynamic).saveToLocal(assignment);
            } catch (e) {
              // Ignorer les erreurs de sauvegarde locale individuelle
              // (peut-être que l'assignation existe déjà)
              developer.log(
                'Error saving EnterpriseModuleUser from Firestore to local database: ${assignment.documentId}',
                name: 'admin.controller',
              );
            }
          }
          
          // Retourner les assignations depuis Firestore
          if (firestoreAssignments.isNotEmpty) {
            developer.log(
              'Loaded ${firestoreAssignments.length} EnterpriseModuleUsers from Firestore (local database was empty)',
              name: 'admin.controller',
            );
            return firestoreAssignments;
          }
        } catch (e) {
          developer.log(
            'Error fetching EnterpriseModuleUsers from Firestore (will use empty local list): $e',
            name: 'admin.controller',
          );
          // Continuer avec la liste locale (vide)
        }
      }
      
      return localAssignments;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting EnterpriseModuleUsers from local database, trying Firestore: $e',
        name: 'admin.controller',
        error: e,
        stackTrace: stackTrace,
      );
      
      // En cas d'erreur locale, essayer Firestore
      if (firestoreSync != null) {
        try {
          final firestoreAssignments = await firestoreSync!.pullEnterpriseModuleUsersFromFirestore();
          developer.log(
            'Loaded ${firestoreAssignments.length} EnterpriseModuleUsers from Firestore (local database error)',
            name: 'admin.controller',
          );
          return firestoreAssignments;
        } catch (e) {
          developer.log(
            'Error fetching EnterpriseModuleUsers from Firestore: $e',
            name: 'admin.controller',
          );
          return [];
        }
      }
      
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

  /// Récupère tous les rôles.
  ///
  /// Si la base locale est vide, récupère automatiquement depuis Firestore
  /// et sauvegarde localement pour la prochaine fois.
  Future<List<UserRole>> getAllRoles() async {
    try {
      // Lire UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée
      // La synchronisation avec Firestore est gérée par le sync manager
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

      final deduplicatedRoles = uniqueRoles.values.toList();

      // Si la base locale contient des rôles, les retourner (dédupliqués)
      if (deduplicatedRoles.isNotEmpty) {
        return deduplicatedRoles;
      }

      // Si la base locale est vide, essayer de récupérer depuis Firestore
      // UNIQUEMENT si la base locale est vraiment vide (pas de lecture simultanée)
      if (firestoreSync != null) {
        try {
          final firestoreRoles = await firestoreSync!.pullRolesFromFirestore();

          // Sauvegarder chaque rôle dans la base locale SANS déclencher de sync
          // (ces rôles viennent déjà de Firestore, pas besoin de les re-synchroniser)
          for (final role in firestoreRoles) {
            try {
              // Utiliser directement saveToLocal pour éviter de mettre dans la queue de sync
              // Les rôles viennent déjà de Firestore, donc pas besoin de les re-sync
              await (_repository as dynamic).saveToLocal(role);
            } catch (e) {
              // Ignorer les erreurs de sauvegarde locale individuelle
              // (peut-être que le rôle existe déjà)
              developer.log(
                'Error saving role from Firestore to local database: ${role.id}',
                name: 'admin.controller',
              );
            }
          }

          // Retourner les rôles depuis Firestore (dédupliqués aussi)
          if (firestoreRoles.isNotEmpty) {
            developer.log(
              'Loaded ${firestoreRoles.length} roles from Firestore (local database was empty)',
              name: 'admin.controller',
            );
            // Dédupliquer aussi les rôles de Firestore au cas où
            final uniqueFirestoreRoles = <String, UserRole>{};
            for (final role in firestoreRoles) {
              if (!uniqueFirestoreRoles.containsKey(role.id)) {
                uniqueFirestoreRoles[role.id] = role;
              }
            }
            return uniqueFirestoreRoles.values.toList();
          }
        } catch (e) {
          developer.log(
            'Error fetching roles from Firestore (will use empty local list): $e',
            name: 'admin.controller',
          );
          // Continuer avec la liste locale (vide)
        }
      }

      return deduplicatedRoles;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting all roles from local database, trying Firestore: $e',
        name: 'admin.controller',
        error: e,
        stackTrace: stackTrace,
      );

      // En cas d'erreur locale, essayer Firestore
      if (firestoreSync != null) {
        try {
          final firestoreRoles = await firestoreSync!.pullRolesFromFirestore();
          developer.log(
            'Loaded ${firestoreRoles.length} roles from Firestore (local database error)',
            name: 'admin.controller',
          );
          return firestoreRoles;
        } catch (e) {
          developer.log(
            'Error fetching roles from Firestore: $e',
            name: 'admin.controller',
          );
          return [];
        }
      }

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
        throw Exception(
          'Permission refusée : Vous n\'avez pas les droits pour créer des rôles. '
          'Contactez un administrateur pour obtenir les permissions nécessaires.',
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
    } catch (e) {
      // Si c'est déjà une exception avec un message clair, la propager
      if (e is Exception) {
        rethrow;
      }
      // Sinon, envelopper dans une exception avec message clair
      throw Exception('Erreur lors de la création du rôle: ${e.toString()}');
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
        throw Exception(
          'Permission refusée : Vous n\'avez pas les droits pour modifier des rôles. '
          'Contactez un administrateur pour obtenir les permissions nécessaires.',
        );
      }
    }

    try {
      // Get old role if not provided
      final oldRoleData =
          oldRole ??
          (await _repository.getModuleRoles(role.id)).firstWhere(
            (r) => r.id == role.id,
            orElse: () => throw Exception('Rôle non trouvé: ${role.id}'),
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
    } catch (e) {
      // Si c'est déjà une exception avec un message clair, la propager
      if (e is Exception) {
        rethrow;
      }
      // Sinon, envelopper dans une exception avec message clair
      throw Exception(
        'Erreur lors de la modification du rôle: ${e.toString()}',
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
        throw Exception(
          'Permission refusée : Vous n\'avez pas les droits pour supprimer des rôles. '
          'Contactez un administrateur pour obtenir les permissions nécessaires.',
        );
      }
    }

    try {
      // Get role data if not provided
      final role =
          roleData ??
          (await _repository.getAllRoles()).firstWhere(
            (r) => r.id == roleId,
            orElse: () => throw Exception('Rôle non trouvé: $roleId'),
          );

      await _repository.deleteRole(roleId);

      // Delete from Firestore
      if (firestoreSync != null) {
        try {
          await firestoreSync!.deleteFromFirestore(
            collection: 'roles',
            documentId: roleId,
          );
        } catch (e) {
          // Logger l'erreur mais ne pas bloquer la suppression locale
          developer.log(
            'Error deleting role from Firestore (local deletion succeeded)',
            name: 'admin.controller',
            error: e,
          );
          // Propager l'erreur pour informer l'utilisateur
          if (e is FirebaseException && e.code == 'permission-denied') {
            throw Exception(
              'Permission refusée : Impossible de supprimer le rôle dans Firestore. '
              'Le rôle a été supprimé localement mais la synchronisation a échoué. '
              'Vérifiez les règles de sécurité Firestore.',
            );
          }
          rethrow;
        }
      }

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
    } catch (e) {
      // Si c'est déjà une exception avec un message clair, la propager
      if (e is Exception) {
        rethrow;
      }
      // Sinon, envelopper dans une exception avec message clair
      throw Exception('Erreur lors de la suppression du rôle: ${e.toString()}');
    }
  }
}

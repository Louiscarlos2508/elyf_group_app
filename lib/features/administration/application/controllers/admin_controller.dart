import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../domain/repositories/admin_repository.dart';

/// Controller pour gérer les opérations d'administration.
class AdminController {
  AdminController(this._repository);

  final AdminRepository _repository;

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
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser,
  ) async {
    return await _repository.assignUserToEnterprise(enterpriseModuleUser);
  }

  /// Met à jour le rôle d'un utilisateur dans une entreprise et un module.
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    String roleId,
  ) async {
    return await _repository.updateUserRole(
      userId,
      enterpriseId,
      moduleId,
      roleId,
    );
  }

  /// Met à jour les permissions personnalisées d'un utilisateur.
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions,
  ) async {
    return await _repository.updateUserPermissions(
      userId,
      enterpriseId,
      moduleId,
      permissions,
    );
  }

  /// Retire un utilisateur d'une entreprise et d'un module.
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    return await _repository.removeUserFromEnterprise(
      userId,
      enterpriseId,
      moduleId,
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
  Future<void> createRole(UserRole role) async {
    return await _repository.createRole(role);
  }

  /// Met à jour un rôle existant.
  Future<void> updateRole(UserRole role) async {
    return await _repository.updateRole(role);
  }

  /// Supprime un rôle (si ce n'est pas un rôle système).
  Future<void> deleteRole(String roleId) async {
    return await _repository.deleteRole(roleId);
  }
}


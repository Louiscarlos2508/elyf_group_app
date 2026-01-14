import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/services/audit/audit_service.dart';
import '../../data/services/firestore_sync_service.dart';
import '../../domain/services/validation/permission_validator_service.dart';
import 'role_controller.dart';
import 'user_assignment_controller.dart';

/// Controller pour gérer les opérations d'administration.
///
/// Facade qui délègue aux controllers spécialisés :
/// - RoleController pour la gestion des rôles
/// - UserAssignmentController pour la gestion des assignations
///
/// Cette classe permet de maintenir la compatibilité avec les providers existants
/// tout en divisant les responsabilités en controllers plus petits et maintenables.
class AdminController {
  AdminController(
    AdminRepository repository, {
    AuditService? auditService,
    FirestoreSyncService? firestoreSync,
    PermissionValidatorService? permissionValidator,
    UserRepository? userRepository,
    EnterpriseRepository? enterpriseRepository,
  }) : _roleController = RoleController(
         repository,
         auditService: auditService,
         firestoreSync: firestoreSync,
         permissionValidator: permissionValidator,
         userRepository: userRepository,
       ),
       _userAssignmentController = UserAssignmentController(
         repository,
         auditService: auditService,
         firestoreSync: firestoreSync,
         permissionValidator: permissionValidator,
         userRepository: userRepository,
         enterpriseRepository: enterpriseRepository,
       );

  final RoleController _roleController;
  final UserAssignmentController _userAssignmentController;

  // ============================================================================
  // Délégation aux méthodes de RoleController
  // ============================================================================

  /// Récupère tous les rôles.
  Future<List<UserRole>> getAllRoles() => _roleController.getAllRoles();

  /// Récupère les rôles pour un module spécifique.
  Future<List<UserRole>> getModuleRoles(String moduleId) =>
      _roleController.getModuleRoles(moduleId);

  /// Crée un nouveau rôle.
  Future<void> createRole(UserRole role, {String? currentUserId}) =>
      _roleController.createRole(role, currentUserId: currentUserId);

  /// Met à jour un rôle existant.
  Future<void> updateRole(
    UserRole role, {
    String? currentUserId,
    UserRole? oldRole,
  }) => _roleController.updateRole(
    role,
    currentUserId: currentUserId,
    oldRole: oldRole,
  );

  /// Supprime un rôle.
  Future<void> deleteRole(
    String roleId, {
    String? currentUserId,
    UserRole? roleData,
  }) => _roleController.deleteRole(
    roleId,
    currentUserId: currentUserId,
    roleData: roleData,
  );

  // ============================================================================
  // Délégation aux méthodes de UserAssignmentController
  // ============================================================================

  /// Récupère tous les accès EnterpriseModuleUser.
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() =>
      _userAssignmentController.getEnterpriseModuleUsers();

  /// Récupère les accès d'un utilisateur spécifique.
  Future<List<EnterpriseModuleUser>> getUserEnterpriseModuleUsers(
    String userId,
  ) => _userAssignmentController.getUserEnterpriseModuleUsers(userId);

  /// Récupère les utilisateurs d'une entreprise.
  Future<List<EnterpriseModuleUser>> getEnterpriseUsers(String enterpriseId) =>
      _userAssignmentController.getEnterpriseUsers(enterpriseId);

  /// Récupère les accès pour une entreprise et un module spécifiques.
  Future<List<EnterpriseModuleUser>>
  getEnterpriseModuleUsersByEnterpriseAndModule(
    String enterpriseId,
    String moduleId,
  ) => _userAssignmentController.getEnterpriseModuleUsersByEnterpriseAndModule(
    enterpriseId,
    moduleId,
  );

  /// Assigne un utilisateur à une entreprise et un module avec un rôle.
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser, {
    String? currentUserId,
  }) => _userAssignmentController.assignUserToEnterprise(
    enterpriseModuleUser,
    currentUserId: currentUserId,
  );

  /// Assigne un utilisateur à plusieurs entreprises avec le même module et rôle.
  Future<void> batchAssignUserToEnterprises({
    required String userId,
    required List<String> enterpriseIds,
    required String moduleId,
    required String roleId,
    required bool isActive,
    String? currentUserId,
  }) => _userAssignmentController.batchAssignUserToEnterprises(
    userId: userId,
    enterpriseIds: enterpriseIds,
    moduleId: moduleId,
    roleId: roleId,
    isActive: isActive,
    currentUserId: currentUserId,
  );

  /// Assigne un utilisateur à plusieurs modules et plusieurs entreprises avec le même rôle.
  Future<void> batchAssignUserToModulesAndEnterprises({
    required String userId,
    required List<String> moduleIds,
    required List<String> enterpriseIds,
    required String roleId,
    required bool isActive,
    String? currentUserId,
  }) => _userAssignmentController.batchAssignUserToModulesAndEnterprises(
    userId: userId,
    moduleIds: moduleIds,
    enterpriseIds: enterpriseIds,
    roleId: roleId,
    isActive: isActive,
    currentUserId: currentUserId,
  );

  /// Met à jour le rôle d'un utilisateur dans une entreprise et un module.
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    String roleId, {
    String? currentUserId,
    String? oldRoleId,
  }) => _userAssignmentController.updateUserRole(
    userId,
    enterpriseId,
    moduleId,
    roleId,
    currentUserId: currentUserId,
    oldRoleId: oldRoleId,
  );

  /// Met à jour les permissions personnalisées d'un utilisateur.
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions, {
    String? currentUserId,
    Set<String>? oldPermissions,
  }) => _userAssignmentController.updateUserPermissions(
    userId,
    enterpriseId,
    moduleId,
    permissions,
    currentUserId: currentUserId,
    oldPermissions: oldPermissions,
  );

  /// Retire un utilisateur d'une entreprise et d'un module.
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId, {
    String? currentUserId,
    EnterpriseModuleUser? oldAssignment,
  }) => _userAssignmentController.removeUserFromEnterprise(
    userId,
    enterpriseId,
    moduleId,
    currentUserId: currentUserId,
    oldAssignment: oldAssignment,
  );
}

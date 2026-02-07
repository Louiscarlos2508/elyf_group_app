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
       ),
       _enterpriseRepository = enterpriseRepository;

  final RoleController _roleController;
  final UserAssignmentController _userAssignmentController;
  final EnterpriseRepository? _enterpriseRepository;

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
    required List<String> roleIds,
    required bool isActive,
    String? currentUserId,
  }) => _userAssignmentController.batchAssignUserToEnterprises(
    userId: userId,
    enterpriseIds: enterpriseIds,
    moduleId: moduleId,
    roleIds: roleIds,
    isActive: isActive,
    currentUserId: currentUserId,
  );

  /// Assigne un utilisateur à plusieurs modules et plusieurs entreprises avec le même rôle.
  Future<void> batchAssignUserToModulesAndEnterprises({
    required String userId,
    required List<String> moduleIds,
    required List<String> enterpriseIds,
    required List<String> roleIds,
    required bool isActive,
    String? currentUserId,
  }) => _userAssignmentController.batchAssignUserToModulesAndEnterprises(
    userId: userId,
    moduleIds: moduleIds,
    enterpriseIds: enterpriseIds,
    roleIds: roleIds,
    isActive: isActive,
    currentUserId: currentUserId,
  );

  /// Met à jour le rôle d'un utilisateur dans une entreprise et un module.
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    List<String> roleIds, {
    String? currentUserId,
    List<String>? oldRoleIds,
  }) => _userAssignmentController.updateUserRole(
    userId,
    enterpriseId,
    moduleId,
    roleIds,
    currentUserId: currentUserId,
    oldRoleIds: oldRoleIds,
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

  /// Surveille tous les rôles (Stream).
  Stream<List<UserRole>> watchAllRoles() => _roleController.watchAllRoles();

  /// Surveille tous les accès EnterpriseModuleUser (Stream).
  Stream<List<EnterpriseModuleUser>> watchEnterpriseModuleUsers() =>
      _userAssignmentController.watchEnterpriseModuleUsers();

  /// Surveille le statut de synchronisation (Stream).
  Stream<bool> watchSyncStatus() => _roleController.watchSyncStatus();

  // ============================================================================
  // Méthodes de vérification d'accès avec héritage hiérarchique
  // ============================================================================

  /// Vérifie si un utilisateur a accès à une entreprise (directement ou via héritage).
  ///
  /// Retourne `true` si :
  /// - L'utilisateur a un accès direct à cette entreprise dans le module spécifié
  /// - L'utilisateur a un accès à une entreprise parente avec `includesChildren = true`
  ///
  /// [userId] : ID de l'utilisateur
  /// [enterpriseId] : ID de l'entreprise à vérifier
  /// [moduleId] : ID du module
  Future<bool> hasAccessToEnterprise({
    required String userId,
    required String enterpriseId,
    required String moduleId,
  }) async {
    // Récupérer tous les accès de l'utilisateur
    final userAccesses = await getUserEnterpriseModuleUsers(userId);

    // Vérifier accès direct
    final directAccess = userAccesses.any((access) =>
        access.enterpriseId == enterpriseId &&
        access.moduleId == moduleId &&
        access.isActive);

    if (directAccess) return true;

    // Vérifier accès via parent avec héritage
    if (_enterpriseRepository != null) {
      final enterprises = await _enterpriseRepository.getAllEnterprises();
      final targetEnterprise = enterprises.firstWhere(
        (e) => e.id == enterpriseId,
        orElse: () => throw Exception('Enterprise not found: $enterpriseId'),
      );

      // Si l'entreprise a un parent, vérifier si l'utilisateur a accès au parent avec includesChildren
      if (targetEnterprise.parentEnterpriseId != null) {
        final parentAccess = userAccesses.any((access) =>
            access.enterpriseId == targetEnterprise.parentEnterpriseId &&
            access.moduleId == moduleId &&
            access.isActive &&
            access.includesChildren);

        if (parentAccess) return true;

        // Récursion : vérifier les parents des parents
        return hasAccessToEnterprise(
          userId: userId,
          enterpriseId: targetEnterprise.parentEnterpriseId!,
          moduleId: moduleId,
        );
      }
    }

    return false;
  }
}

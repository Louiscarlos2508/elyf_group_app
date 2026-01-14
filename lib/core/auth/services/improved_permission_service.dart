import '../entities/enterprise_module_user.dart';
import '../../permissions/entities/user_role.dart';

/// Service de permissions amélioré avec support multi-tenant (entreprise).
///
/// Différence avec PermissionService de base:
/// - Inclut enterpriseId dans toutes les vérifications
/// - Permet à un utilisateur d'avoir des rôles différents selon l'entreprise
/// - Isolé les données par entreprise
abstract class ImprovedPermissionService {
  /// Vérifie si un utilisateur a une permission dans une entreprise et un module spécifiques.
  ///
  /// Exemple:
  /// ```dart
  /// final canCreate = await service.hasPermission(
  ///   'user123',
  ///   'eau_sachet_1',  // Entreprise spécifique
  ///   'eau_minerale',
  ///   'create_production',
  /// );
  /// ```
  Future<bool> hasPermission(
    String userId,
    String enterpriseId, // ← NOUVEAU: Entreprise spécifique
    String moduleId,
    String permissionId,
  );

  /// Récupère l'accès d'un utilisateur dans une entreprise et un module.
  Future<EnterpriseModuleUser?> getEnterpriseModuleUser(
    String userId,
    String enterpriseId,
    String moduleId,
  );

  /// Récupère tous les accès d'un utilisateur (toutes entreprises).
  Future<List<EnterpriseModuleUser>> getUserAccesses(String userId);

  /// Récupère les entreprises accessibles par un utilisateur.
  ///
  /// Retourne la liste des entreprises où l'utilisateur a au moins un accès actif.
  Future<List<String>> getUserEnterprises(String userId);

  /// Récupère les modules accessibles par un utilisateur dans une entreprise.
  ///
  /// Retourne la liste des modules où l'utilisateur a un accès actif dans l'entreprise.
  Future<List<String>> getUserModules(String userId, String enterpriseId);

  /// Vérifie si un utilisateur a accès à une entreprise.
  Future<bool> hasEnterpriseAccess(String userId, String enterpriseId);

  /// Vérifie si un utilisateur a accès à un module dans une entreprise.
  Future<bool> hasModuleAccess(
    String userId,
    String enterpriseId,
    String moduleId,
  );
}

/// Implémentation mock pour le développement.
///
/// TODO: Remplacer par FirestorePermissionService en production.
class MockImprovedPermissionService implements ImprovedPermissionService {
  final Map<String, EnterpriseModuleUser> _accesses = {};
  final Map<String, UserRole> _roles = {};

  MockImprovedPermissionService({bool initializeDefaults = true}) {
    _initializeDefaultRoles();
    if (initializeDefaults) {
      _initializeDefaultAccesses();
    }
  }

  void _initializeDefaultRoles() {
    // Rôle admin avec toutes les permissions
    _roles['admin'] = const UserRole(
      id: 'admin',
      name: 'Administrateur',
      description: 'Accès complet',
      permissions: {'*'},
      isSystemRole: true,
    );

    // Rôle gestionnaire pour eau_minerale
    _roles['gestionnaire_eau_minerale'] = UserRole(
      id: 'gestionnaire_eau_minerale',
      name: 'Gestionnaire Eau Minérale',
      description: 'Gestion complète du module eau minérale',
      permissions: {
        'view_dashboard',
        'view_production',
        'create_production',
        'edit_production',
        'view_sales',
        'create_sale',
        'edit_sale',
        'view_stock',
        'edit_stock',
        'view_finances',
        'create_expense',
        'view_reports',
      },
      isSystemRole: false,
    );
  }

  void _initializeDefaultAccesses() {
    // Utilisateur par défaut avec accès à toutes les entreprises
    final defaultUserId = 'default_user';
    final enterprises = [
      'eau_sachet_1',
      'gaz_1',
      'orange_money_1',
      'immobilier_1',
      'boutique_1',
    ];

    for (final enterpriseId in enterprises) {
      final moduleId = enterpriseId.split('_')[0]; // eau_sachet_1 -> eau
      final access = EnterpriseModuleUser(
        userId: defaultUserId,
        enterpriseId: enterpriseId,
        moduleId: moduleId == 'eau' ? 'eau_minerale' : moduleId,
        roleId: 'admin',
        isActive: true,
        createdAt: DateTime.now(),
      );
      _accesses[access.documentId] = access;
    }
  }

  @override
  Future<bool> hasPermission(
    String userId,
    String enterpriseId,
    String moduleId,
    String permissionId,
  ) async {
    final access = await getEnterpriseModuleUser(
      userId,
      enterpriseId,
      moduleId,
    );
    if (access == null || !access.isActive) {
      return false;
    }

    final role = _roles[access.roleId];
    if (role == null) {
      return false;
    }

    // Wildcard permission
    if (role.hasPermission('*')) {
      return true;
    }

    // Permission du rôle
    if (role.hasPermission(permissionId)) {
      return true;
    }

    // Permissions personnalisées
    return access.customPermissions.contains(permissionId);
  }

  @override
  Future<EnterpriseModuleUser?> getEnterpriseModuleUser(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    final documentId = '${userId}_${enterpriseId}_$moduleId';
    return _accesses[documentId];
  }

  @override
  Future<List<EnterpriseModuleUser>> getUserAccesses(String userId) async {
    return _accesses.values
        .where((access) => access.userId == userId && access.isActive)
        .toList();
  }

  @override
  Future<List<String>> getUserEnterprises(String userId) async {
    final accesses = await getUserAccesses(userId);
    return accesses.map((a) => a.enterpriseId).toSet().toList();
  }

  @override
  Future<List<String>> getUserModules(
    String userId,
    String enterpriseId,
  ) async {
    final accesses = await getUserAccesses(userId);
    return accesses
        .where((a) => a.enterpriseId == enterpriseId)
        .map((a) => a.moduleId)
        .toList();
  }

  @override
  Future<bool> hasEnterpriseAccess(String userId, String enterpriseId) async {
    final accesses = await getUserAccesses(userId);
    return accesses.any((a) => a.enterpriseId == enterpriseId);
  }

  @override
  Future<bool> hasModuleAccess(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    final access = await getEnterpriseModuleUser(
      userId,
      enterpriseId,
      moduleId,
    );
    return access != null && access.isActive;
  }

  // Note: Les méthodes de base.PermissionService ne sont pas implémentées
  // car elles ne supportent pas enterpriseId. Utilisez les méthodes
  // avec enterpriseId ci-dessus.
}

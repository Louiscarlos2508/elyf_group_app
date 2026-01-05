import '../../../../core/permissions/entities/user_role.dart';
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../domain/repositories/admin_repository.dart';

/// Mock implementation of AdminRepository with multi-tenant support.
class MockAdminRepository implements AdminRepository {
  final List<EnterpriseModuleUser> _enterpriseModuleUsers = [];
  final List<UserRole> _roles = [];

  MockAdminRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Add default roles
    _roles.addAll([
      UserRole(
        id: 'admin',
        name: 'Administrateur',
        description: 'Accès complet',
        permissions: {'*'},
        isSystemRole: true,
      ),
      UserRole(
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
      ),
      UserRole(
        id: 'vendeur',
        name: 'Vendeur',
        description: 'Gestion des ventes uniquement',
        permissions: {
          'view_dashboard',
          'view_sales',
          'create_sale',
          'view_stock',
        },
      ),
    ]);

    // Add some mock enterprise module users
    final now = DateTime.now();
    _enterpriseModuleUsers.addAll([
      EnterpriseModuleUser(
        userId: 'user-1',
        enterpriseId: 'eau_sachet_1',
        moduleId: 'eau_minerale',
        roleId: 'admin',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      EnterpriseModuleUser(
        userId: 'user-2',
        enterpriseId: 'eau_sachet_1',
        moduleId: 'eau_minerale',
        roleId: 'vendeur',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
      ),
      EnterpriseModuleUser(
        userId: 'user-1',
        enterpriseId: 'gaz_1',
        moduleId: 'gaz',
        roleId: 'admin',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
    ]);
  }

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseModuleUsers() async {
    return List.from(_enterpriseModuleUsers);
  }

  @override
  Future<List<EnterpriseModuleUser>> getUserEnterpriseModuleUsers(
    String userId,
  ) async {
    return _enterpriseModuleUsers
        .where((u) => u.userId == userId)
        .toList();
  }

  @override
  Future<List<EnterpriseModuleUser>> getEnterpriseUsers(
    String enterpriseId,
  ) async {
    return _enterpriseModuleUsers
        .where((u) => u.enterpriseId == enterpriseId)
        .toList();
  }

  @override
  Future<List<EnterpriseModuleUser>>
      getEnterpriseModuleUsersByEnterpriseAndModule(
    String enterpriseId,
    String moduleId,
  ) async {
    return _enterpriseModuleUsers
        .where(
          (u) => u.enterpriseId == enterpriseId && u.moduleId == moduleId,
        )
        .toList();
  }

  @override
  Future<void> assignUserToEnterprise(
    EnterpriseModuleUser enterpriseModuleUser,
  ) async {
    final documentId = enterpriseModuleUser.documentId;
    _enterpriseModuleUsers.removeWhere(
      (u) => u.documentId == documentId,
    );
    _enterpriseModuleUsers.add(enterpriseModuleUser);
  }

  @override
  Future<void> updateUserRole(
    String userId,
    String enterpriseId,
    String moduleId,
    String roleId,
  ) async {
    final documentId = '${userId}_${enterpriseId}_$moduleId';
    final index = _enterpriseModuleUsers.indexWhere(
      (u) => u.documentId == documentId,
    );
    if (index != -1) {
      _enterpriseModuleUsers[index] = _enterpriseModuleUsers[index].copyWith(
        roleId: roleId,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateUserPermissions(
    String userId,
    String enterpriseId,
    String moduleId,
    Set<String> permissions,
  ) async {
    final documentId = '${userId}_${enterpriseId}_$moduleId';
    final index = _enterpriseModuleUsers.indexWhere(
      (u) => u.documentId == documentId,
    );
    if (index != -1) {
      _enterpriseModuleUsers[index] = _enterpriseModuleUsers[index].copyWith(
        customPermissions: permissions,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> removeUserFromEnterprise(
    String userId,
    String enterpriseId,
    String moduleId,
  ) async {
    final documentId = '${userId}_${enterpriseId}_$moduleId';
    _enterpriseModuleUsers.removeWhere((u) => u.documentId == documentId);
  }

  @override
  Future<List<UserRole>> getAllRoles() async {
    return List.from(_roles);
  }

  @override
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    // For now, return all roles. In real implementation, filter by module
    return List.from(_roles);
  }

  @override
  Future<void> createRole(UserRole role) async {
    _roles.add(role);
  }

  @override
  Future<void> updateRole(UserRole role) async {
    final index = _roles.indexWhere((r) => r.id == role.id);
    if (index != -1) {
      _roles[index] = role;
    }
  }

  @override
  Future<void> deleteRole(String roleId) async {
    final role = _roles.firstWhere((r) => r.id == roleId);
    if (!role.isSystemRole) {
      _roles.removeWhere((r) => r.id == roleId);
    }
  }
}


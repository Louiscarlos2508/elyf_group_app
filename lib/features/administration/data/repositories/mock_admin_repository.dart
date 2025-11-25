import '../../../../core/permissions/entities/module_user.dart';
import '../../../../core/permissions/entities/user_role.dart';
import '../../domain/repositories/admin_repository.dart';

/// Mock implementation of AdminRepository.
class MockAdminRepository implements AdminRepository {
  final List<ModuleUser> _moduleUsers = [];
  final List<UserRole> _roles = [];

  MockAdminRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Add default roles
    _roles.addAll([
      UserRole(
        id: 'responsable',
        name: 'Responsable',
        description: 'Accès complet au module',
        permissions: {'*'},
        isSystemRole: true,
      ),
      UserRole(
        id: 'gestionnaire',
        name: 'Gestionnaire',
        description: 'Gestion des opérations courantes',
        permissions: {
          'view_dashboard',
          'view_production',
          'create_production',
          'view_sales',
          'create_sale',
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

    // Add some mock users
    _moduleUsers.addAll([
      ModuleUser(
        userId: 'user-1',
        moduleId: 'eau_minerale',
        roleId: 'responsable',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ModuleUser(
        userId: 'user-2',
        moduleId: 'eau_minerale',
        roleId: 'vendeur',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ]);
  }

  @override
  Future<List<ModuleUser>> getModuleUsers(String moduleId) async {
    return _moduleUsers
        .where((u) => u.moduleId == moduleId)
        .toList();
  }

  @override
  Future<void> addUserToModule(ModuleUser moduleUser) async {
    _moduleUsers.removeWhere(
      (u) => u.userId == moduleUser.userId && u.moduleId == moduleUser.moduleId,
    );
    _moduleUsers.add(moduleUser);
  }

  @override
  Future<void> updateUserRole(
    String userId,
    String moduleId,
    String roleId,
  ) async {
    final index = _moduleUsers.indexWhere(
      (u) => u.userId == userId && u.moduleId == moduleId,
    );
    if (index != -1) {
      _moduleUsers[index] = _moduleUsers[index].copyWith(
        roleId: roleId,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateUserPermissions(
    String userId,
    String moduleId,
    Set<String> permissions,
  ) async {
    final index = _moduleUsers.indexWhere(
      (u) => u.userId == userId && u.moduleId == moduleId,
    );
    if (index != -1) {
      _moduleUsers[index] = _moduleUsers[index].copyWith(
        customPermissions: permissions,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> removeUserFromModule(String userId, String moduleId) async {
    _moduleUsers.removeWhere(
      (u) => u.userId == userId && u.moduleId == moduleId,
    );
  }

  @override
  Future<List<UserRole>> getAllRoles() async {
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

  @override
  Future<List<UserRole>> getModuleRoles(String moduleId) async {
    // For now, return all roles. In real implementation, filter by module
    return List.from(_roles);
  }
}


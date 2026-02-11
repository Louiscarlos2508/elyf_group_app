/// Factories pour créer des mocks cohérents dans les tests.
library;

import 'package:elyf_groupe_app/core/permissions/entities/user_role.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import 'test_helpers.dart';

/// Crée un UserRole de test.
UserRole createTestUserRole({
  String? id,
  String? name,
  String? description,
  Set<String>? permissions,
  bool? isSystemRole,
  String? moduleId,
}) {
  return UserRole(
    id: id ?? 'role-1',
    name: name ?? 'Test Role',
    description: description ?? 'Test role description',
    permissions: permissions ?? {'read', 'write'},
    isSystemRole: isSystemRole ?? false,
    moduleId: moduleId ?? 'general',
  );
}

/// Crée un EnterpriseModuleUser de test.
EnterpriseModuleUser createTestEnterpriseModuleUser({
  String? userId,
  String? enterpriseId,
  String? moduleId,
  List<String>? roleIds,
  Set<String>? customPermissions,
  bool? isActive,
}) {
  return EnterpriseModuleUser(
    userId: userId ?? TestIds.userId1,
    enterpriseId: enterpriseId ?? TestIds.enterprise1,
    moduleId: moduleId ?? TestIds.moduleGaz,
    roleIds: roleIds ?? ['role-1'],
    customPermissions: customPermissions ?? {},
    isActive: isActive ?? true,
  );
}

/// Crée un UserRole avec toutes les permissions (admin).
UserRole createAdminRole({String? id, String? name}) {
  return createTestUserRole(
    id: id ?? 'admin-role',
    name: name ?? 'Admin',
    description: 'Administrator role with all permissions',
    permissions: {'*'}, // Wildcard permission
    isSystemRole: true,
  );
}

/// Crée un UserRole avec permissions limitées (user).
UserRole createUserRole({String? id, String? name}) {
  return createTestUserRole(
    id: id ?? 'user-role',
    name: name ?? 'User',
    description: 'Standard user role with limited permissions',
    permissions: {'read'},
    isSystemRole: false,
  );
}

/// Crée un EnterpriseModuleUser actif.
EnterpriseModuleUser createActiveUser({
  String? userId,
  String? enterpriseId,
  String? moduleId,
  List<String>? roleIds,
}) {
  return createTestEnterpriseModuleUser(
    userId: userId,
    enterpriseId: enterpriseId,
    moduleId: moduleId,
    roleIds: roleIds,
    isActive: true,
  );
}

/// Crée un EnterpriseModuleUser inactif.
EnterpriseModuleUser createInactiveUser({
  String? userId,
  String? enterpriseId,
  String? moduleId,
  List<String>? roleIds,
}) {
  return createTestEnterpriseModuleUser(
    userId: userId,
    enterpriseId: enterpriseId,
    moduleId: moduleId,
    roleIds: roleIds,
    isActive: false,
  );
}

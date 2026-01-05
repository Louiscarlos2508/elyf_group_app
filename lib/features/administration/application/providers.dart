import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/services/permission_service.dart'
    show PermissionService, MockPermissionService;
import '../../../core/permissions/services/permission_registry.dart';
import '../data/repositories/mock_admin_repository.dart';
import '../data/repositories/mock_enterprise_repository.dart';
import '../data/repositories/mock_user_repository.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/repositories/enterprise_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/entities/enterprise.dart';
import '../domain/entities/user.dart';
import '../../../core/auth/entities/enterprise_module_user.dart';
import '../../../core/permissions/entities/user_role.dart';

/// Provider for admin repository
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => MockAdminRepository(),
);

/// Provider for user repository
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => MockUserRepository(),
);

/// Provider for permission service
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => MockPermissionService(),
);

/// Provider for permission registry
final permissionRegistryProvider = Provider<PermissionRegistry>(
  (ref) => PermissionRegistry.instance,
);

/// Provider for enterprise repository
final enterpriseRepositoryProvider = Provider<EnterpriseRepository>(
  (ref) => MockEnterpriseRepository(),
);

/// Provider pour récupérer toutes les entreprises
final enterprisesProvider = FutureProvider<List<Enterprise>>(
  (ref) => ref.watch(enterpriseRepositoryProvider).getAllEnterprises(),
);

/// Provider pour récupérer les entreprises par type
final enterprisesByTypeProvider =
    FutureProvider.family<List<Enterprise>, String>(
  (ref, type) =>
      ref.watch(enterpriseRepositoryProvider).getEnterprisesByType(type),
);

/// Provider pour récupérer une entreprise par ID
final enterpriseByIdProvider = FutureProvider.family<Enterprise?, String>(
  (ref, enterpriseId) =>
      ref.watch(enterpriseRepositoryProvider).getEnterpriseById(enterpriseId),
);

/// Provider pour récupérer tous les utilisateurs
final usersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(userRepositoryProvider).getAllUsers(),
);

/// Provider pour rechercher des utilisateurs
final searchUsersProvider =
    FutureProvider.family<List<User>, String>(
  (ref, query) => ref.watch(userRepositoryProvider).searchUsers(query),
);

/// Provider pour récupérer les accès EnterpriseModuleUser
final enterpriseModuleUsersProvider =
    FutureProvider<List<EnterpriseModuleUser>>(
  (ref) => ref.watch(adminRepositoryProvider).getEnterpriseModuleUsers(),
);

/// Provider pour récupérer les accès d'un utilisateur
final userEnterpriseModuleUsersProvider =
    FutureProvider.family<List<EnterpriseModuleUser>, String>(
  (ref, userId) =>
      ref.watch(adminRepositoryProvider).getUserEnterpriseModuleUsers(userId),
);

/// Provider pour récupérer tous les rôles
final rolesProvider = FutureProvider<List<UserRole>>(
  (ref) => ref.watch(adminRepositoryProvider).getAllRoles(),
);

/// Provider pour les statistiques d'administration
final adminStatsProvider = FutureProvider<AdminStats>(
  (ref) async {
    final enterprises = await ref.watch(enterprisesProvider.future);
    final users = await ref.watch(usersProvider.future);
    final adminRepo = ref.watch(adminRepositoryProvider);
    final roles = await adminRepo.getAllRoles();
    final enterpriseModuleUsers =
        await ref.watch(enterpriseModuleUsersProvider.future);

    return AdminStats(
      totalEnterprises: enterprises.length,
      activeEnterprises: enterprises.where((e) => e.isActive).length,
      enterprisesByType: {
        for (var type in [
          'eau_minerale',
          'gaz',
          'orange_money',
          'immobilier',
          'boutique'
        ])
          type: enterprises.where((e) => e.type == type).length,
      },
      totalRoles: roles.length,
      totalUsers: users.length,
      activeUsers: users.where((u) => u.isActive).length,
      totalAssignments: enterpriseModuleUsers.length,
    );
  },
);

/// Statistiques d'administration
class AdminStats {
  const AdminStats({
    required this.totalEnterprises,
    required this.activeEnterprises,
    required this.enterprisesByType,
    required this.totalRoles,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalAssignments,
  });

  final int totalEnterprises;
  final int activeEnterprises;
  final Map<String, int> enterprisesByType;
  final int totalRoles;
  final int totalUsers;
  final int activeUsers;
  final int totalAssignments;
}


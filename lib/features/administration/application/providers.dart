import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/services/permission_service.dart'
    show PermissionService, MockPermissionService;
import '../../../core/permissions/services/permission_registry.dart';
import '../data/repositories/mock_admin_repository.dart';
import '../data/repositories/mock_enterprise_repository.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/repositories/enterprise_repository.dart';
import '../domain/entities/enterprise.dart';

/// Provider for admin repository
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => MockAdminRepository(),
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

/// Provider pour les statistiques d'administration
final adminStatsProvider = FutureProvider<AdminStats>(
  (ref) async {
    final enterprises = await ref.watch(enterprisesProvider.future);
    final adminRepo = ref.watch(adminRepositoryProvider);
    final roles = await adminRepo.getAllRoles();

    return AdminStats(
      totalEnterprises: enterprises.length,
      activeEnterprises: enterprises.where((e) => e.isActive).length,
      enterprisesByType: {
        for (var type in ['eau_minerale', 'gaz', 'orange_money', 'immobilier', 'boutique'])
          type: enterprises.where((e) => e.type == type).length,
      },
      totalRoles: roles.length,
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
  });

  final int totalEnterprises;
  final int activeEnterprises;
  final Map<String, int> enterprisesByType;
  final int totalRoles;
}


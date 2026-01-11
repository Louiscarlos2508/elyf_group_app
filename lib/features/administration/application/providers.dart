import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/providers.dart';
import '../../../core/permissions/services/permission_service.dart' show PermissionService, MockPermissionService;
import '../../../core/permissions/services/permission_registry.dart';
import '../data/repositories/admin_offline_repository.dart';
import '../data/repositories/enterprise_offline_repository.dart';
import '../data/repositories/user_offline_repository.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/repositories/enterprise_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/entities/enterprise.dart';
import '../domain/entities/user.dart';
import '../../../core/auth/entities/enterprise_module_user.dart';
import '../../../core/permissions/entities/user_role.dart';
import '../domain/services/enterprise_type_service.dart';
import '../domain/services/filtering/user_filter_service.dart';
import '../domain/services/role_statistics_service.dart';
import '../domain/services/audit/audit_service.dart';
import '../domain/services/validation/permission_validator_service.dart';
import '../data/services/audit/audit_offline_service.dart';
import '../data/services/firebase_auth_integration_service.dart';
import '../data/services/firestore_sync_service.dart';
import '../data/services/realtime_sync_service.dart';
import 'controllers/admin_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/enterprise_controller.dart';
import 'controllers/audit_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/services/auth_service.dart';
import '../../../core/auth/providers.dart' show authServiceProvider;

/// Provider for admin repository (offline-first)
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminOfflineRepository(
    driftService: ref.watch(driftServiceProvider),
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  ),
);

/// Provider for user repository (offline-first)
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserOfflineRepository(
    driftService: ref.watch(driftServiceProvider),
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  ),
);

/// Provider for permission service
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => MockPermissionService(),
);

/// Provider for permission registry
final permissionRegistryProvider = Provider<PermissionRegistry>(
  (ref) => PermissionRegistry.instance,
);

/// Provider for enterprise repository (offline-first)
final enterpriseRepositoryProvider = Provider<EnterpriseRepository>(
  (ref) => EnterpriseOfflineRepository(
    driftService: ref.watch(driftServiceProvider),
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  ),
);

/// Provider for enterprise type service
final enterpriseTypeServiceProvider = Provider<EnterpriseTypeService>(
  (ref) => EnterpriseTypeService(),
);

/// Provider for user filter service
final userFilterServiceProvider = Provider<UserFilterService>(
  (ref) => UserFilterService(),
);

/// Provider for role statistics service
final roleStatisticsServiceProvider = Provider<RoleStatisticsService>(
  (ref) => RoleStatisticsService(),
);

/// Provider for audit service
final auditServiceProvider = Provider<AuditService>(
  (ref) => AuditOfflineService(
    driftService: ref.watch(driftServiceProvider),
    firestoreSync: ref.watch(firestoreSyncServiceProvider),
  ),
);

/// Provider for permission validator service
final permissionValidatorServiceProvider = Provider<PermissionValidatorService>(
  (ref) => PermissionValidatorService(
    permissionService: ref.watch(permissionServiceProvider),
    ref: ref,
  ),
);

/// Provider for Firebase Auth integration service
final firebaseAuthIntegrationServiceProvider = Provider<FirebaseAuthIntegrationService>(
  (ref) => FirebaseAuthIntegrationService(
    authService: ref.watch(authServiceProvider),
  ),
);

/// Provider for Firestore sync service
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>(
  (ref) => FirestoreSyncService(
    driftService: ref.watch(driftServiceProvider),
    firestore: FirebaseFirestore.instance,
  ),
);

/// Provider for realtime sync service
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>(
  (ref) => RealtimeSyncService(
    driftService: ref.watch(driftServiceProvider),
    firestore: FirebaseFirestore.instance,
    firestoreSync: ref.watch(firestoreSyncServiceProvider),
  ),
);

/// Provider for admin controller
/// 
/// Includes audit trail, Firestore sync and permission validation for roles and assignments.
final adminControllerProvider = Provider<AdminController>(
  (ref) => AdminController(
    ref.watch(adminRepositoryProvider),
    auditService: ref.watch(auditServiceProvider),
    firestoreSync: ref.watch(firestoreSyncServiceProvider),
    permissionValidator: ref.watch(permissionValidatorServiceProvider),
    userRepository: ref.watch(userRepositoryProvider),
  ),
);

/// Provider for user controller
/// 
/// Includes Firebase Auth integration, Firestore sync, audit trail and permission validation.
final userControllerProvider = Provider<UserController>(
  (ref) => UserController(
    ref.watch(userRepositoryProvider),
    auditService: ref.watch(auditServiceProvider),
    permissionValidator: ref.watch(permissionValidatorServiceProvider),
    firebaseAuthIntegration: ref.watch(firebaseAuthIntegrationServiceProvider),
    firestoreSync: ref.watch(firestoreSyncServiceProvider),
  ),
);

/// Provider for enterprise controller
/// 
/// Includes audit trail, Firestore sync and permission validation for enterprises.
final enterpriseControllerProvider = Provider<EnterpriseController>(
  (ref) => EnterpriseController(
    ref.watch(enterpriseRepositoryProvider),
    auditService: ref.watch(auditServiceProvider),
    firestoreSync: ref.watch(firestoreSyncServiceProvider),
    permissionValidator: ref.watch(permissionValidatorServiceProvider),
    userRepository: ref.watch(userRepositoryProvider),
  ),
);

/// Provider for audit controller
final auditControllerProvider = Provider<AuditController>(
  (ref) => AuditController(ref.watch(auditServiceProvider)),
);

/// Provider pour récupérer toutes les entreprises
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final enterprisesProvider = FutureProvider.autoDispose<List<Enterprise>>(
  (ref) => ref.watch(enterpriseControllerProvider).getAllEnterprises(),
);

/// Provider pour récupérer les entreprises par type
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final enterprisesByTypeProvider =
    FutureProvider.autoDispose.family<List<Enterprise>, String>(
  (ref, type) =>
      ref.watch(enterpriseControllerProvider).getEnterprisesByType(type),
);

/// Provider pour récupérer une entreprise par ID
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final enterpriseByIdProvider = FutureProvider.autoDispose.family<Enterprise?, String>(
  (ref, enterpriseId) =>
      ref.watch(enterpriseControllerProvider).getEnterpriseById(enterpriseId),
);

/// Provider pour récupérer tous les utilisateurs
/// 
/// Utilise le controller pour respecter l'architecture.
/// 
/// ⚠️ Note: Pour de meilleures performances, utilisez paginatedUsersProvider
/// pour les grandes listes.
final usersProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(userControllerProvider).getAllUsers(),
);

/// Provider pour rechercher des utilisateurs
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
/// Limite les résultats à 100 pour améliorer les performances.
final searchUsersProvider =
    FutureProvider.autoDispose.family<List<User>, String>(
  (ref, query) => ref.watch(userControllerProvider).searchUsers(query),
);

/// Provider pour récupérer les accès EnterpriseModuleUser
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final enterpriseModuleUsersProvider =
    FutureProvider.autoDispose<List<EnterpriseModuleUser>>(
  (ref) => ref.watch(adminControllerProvider).getEnterpriseModuleUsers(),
);

/// Provider pour récupérer les accès d'un utilisateur
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final userEnterpriseModuleUsersProvider =
    FutureProvider.autoDispose.family<List<EnterpriseModuleUser>, String>(
  (ref, userId) =>
      ref.watch(adminControllerProvider).getUserEnterpriseModuleUsers(userId),
);

/// Provider pour récupérer tous les rôles
/// 
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final rolesProvider = FutureProvider.autoDispose<List<UserRole>>(
  (ref) => ref.watch(adminControllerProvider).getAllRoles(),
);

/// Provider pour les statistiques d'administration
/// 
/// Utilise les controllers pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
/// Optimisé avec Future.wait pour charger en parallèle.
final adminStatsProvider = FutureProvider.autoDispose<AdminStats>(
  (ref) async {
    // Load in parallel for better performance
    final results = await Future.wait([
      ref.watch(enterprisesProvider.future),
      ref.watch(usersProvider.future),
      ref.watch(adminControllerProvider).getAllRoles(),
      ref.watch(enterpriseModuleUsersProvider.future),
    ]);

    final enterprises = results[0] as List<Enterprise>;
    final users = results[1] as List<User>;
    final roles = results[2] as List<UserRole>;
    final enterpriseModuleUsers = results[3] as List<EnterpriseModuleUser>;

    // Memoize calculations
    final activeEnterprises = enterprises.where((e) => e.isActive).length;
    final activeUsers = users.where((u) => u.isActive).length;
    
    final enterprisesByType = <String, int>{};
    for (final type in ['eau_minerale', 'gaz', 'orange_money', 'immobilier', 'boutique']) {
      enterprisesByType[type] = enterprises.where((e) => e.type == type).length;
    }

    return AdminStats(
      totalEnterprises: enterprises.length,
      activeEnterprises: activeEnterprises,
      enterprisesByType: enterprisesByType,
      totalRoles: roles.length,
      totalUsers: users.length,
      activeUsers: activeUsers,
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


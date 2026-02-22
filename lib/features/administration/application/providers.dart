import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/offline/providers.dart';
import '../../../core/permissions/services/permission_service.dart'
    show PermissionService;
import '../../../core/permissions/services/permission_registry.dart';
import '../data/repositories/enterprise_offline_repository.dart';
import '../data/repositories/enterprise_firestore_repository.dart';
import '../domain/repositories/admin_repository.dart';
import '../domain/repositories/enterprise_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../data/repositories/admin_offline_repository.dart';
import '../data/repositories/user_offline_repository.dart';
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
import 'controllers/user_assignment_controller.dart';
import '../../../core/auth/services/auth_service.dart';
import '../../../core/firebase/providers.dart' show firestoreProvider;
import '../data/repositories/admin_firestore_repository.dart';
import '../data/repositories/user_firestore_repository.dart';

/// Provider for admin repository (platform-aware)
/// - Web: Utilise Firestore directement (online-only)
/// - Mobile/Desktop: Utilise Drift (offline-first)
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) {
    if (kIsWeb) {
      return AdminFirestoreRepository(
        firestore: ref.watch(firestoreProvider),
        ref: ref,
      );
    } else {
      return AdminOfflineRepository(
        driftService: ref.watch(driftServiceProvider),
        syncManager: ref.watch(syncManagerProvider),
        connectivityService: ref.watch(connectivityServiceProvider),
      );
    }
  },
);

/// Provider for user repository (platform-aware)
/// - Web: Utilise Firestore directement (online-only)
/// - Mobile/Desktop: Utilise Drift (offline-first)
final userRepositoryProvider = Provider<UserRepository>(
  (ref) {
    if (kIsWeb) {
      return UserFirestoreRepository(
        firestore: ref.watch(firestoreProvider),
      );
    } else {
      return UserOfflineRepository(
        driftService: ref.watch(driftServiceProvider),
        syncManager: ref.watch(syncManagerProvider),
        connectivityService: ref.watch(connectivityServiceProvider),
      );
    }
  },
);

/// Provider for permission service
///
/// Redirigé vers unifiedPermissionServiceProvider de core/auth pour une source de vérité unique.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return ref.watch(unifiedPermissionServiceProvider);
});

/// Provider for permission registry
final permissionRegistryProvider = Provider<PermissionRegistry>(
  (ref) => PermissionRegistry.instance,
);

/// Provider for enterprise repository (platform-aware)
/// - Web: Utilise Firestore directement (online-only)
/// - Mobile/Desktop: Utilise Drift (offline-first)
final enterpriseRepositoryProvider = Provider<EnterpriseRepository>(
  (ref) {
    if (kIsWeb) {
      // Sur web: utiliser Firestore directement
      return EnterpriseFirestoreRepository(
        firestore: FirebaseFirestore.instance,
      );
    } else {
      // Sur mobile/desktop: utiliser Drift offline-first
      return EnterpriseOfflineRepository(
        driftService: ref.watch(driftServiceProvider),
        syncManager: ref.watch(syncManagerProvider),
        connectivityService: ref.watch(connectivityServiceProvider),
      );
    }
  },
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
final firebaseAuthIntegrationServiceProvider =
    Provider<FirebaseAuthIntegrationService>(
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

/// Provider pour surveiller si une synchronisation administrative est en cours.
final isAdminSyncingProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(realtimeSyncServiceProvider).syncStatusStream,
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
    enterpriseRepository: ref.watch(enterpriseRepositoryProvider),
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
    adminRepository: ref.watch(adminRepositoryProvider),
  ),
);

/// Provider for user assignment controller
///
/// Includes audit trail, Firestore sync and permission validation for assignments.
final userAssignmentControllerProvider = Provider<UserAssignmentController>(
  (ref) => UserAssignmentController(
    ref.watch(adminRepositoryProvider),
    auditService: ref.watch(auditServiceProvider),
    firestoreSync: ref.watch(firestoreSyncServiceProvider),
    permissionValidator: ref.watch(permissionValidatorServiceProvider),
    userRepository: ref.watch(userRepositoryProvider),
    enterpriseRepository: ref.watch(enterpriseRepositoryProvider),
  ),
);

/// Provider for audit controller
final auditControllerProvider = Provider<AuditController>(
  (ref) => AuditController(ref.watch(auditServiceProvider)),
);

/// Provider pour surveiller toutes les entreprises (Stream)
///
/// Utilise le controller pour respecter l'architecture.
final enterprisesProvider = StreamProvider.autoDispose<List<Enterprise>>(
  (ref) => ref.watch(enterpriseControllerProvider).watchAllEnterprises(),
);

/// Provider pour récupérer tous les points de vente depuis toutes les entreprises
///
/// Convertit les points de vente en Enterprise-like objects pour l'affichage dans la liste.
final allPointsOfSaleProvider = FutureProvider.autoDispose<List<Enterprise>>(
  (ref) async {
    developer.log(
      '🔵 allPointsOfSaleProvider: Début de la récupération des points de vente',
      name: 'allPointsOfSaleProvider',
    );
    
    // Récupérer toutes les entreprises pour mapper les parentEnterpriseId
    final enterprises = await ref.watch(enterprisesProvider.future);
    final enterprisesMap = {for (var e in enterprises) e.id: e};
    
    developer.log(
      '🔵 allPointsOfSaleProvider: ${enterprises.length} entreprises récupérées',
      name: 'allPointsOfSaleProvider',
    );
    
    // Récupérer tous les points de vente
    // Essayer d'abord depuis Drift, puis depuis Firestore si nécessaire
    final driftService = ref.watch(driftServiceProvider);
    final List<Map<String, dynamic>> posDataList = [];
    
    // 1. Essayer de récupérer depuis Drift
    try {
      final posRecords = await driftService.records.listForCollection(
        collectionName: 'pointOfSale',
        moduleType: 'gaz',
      );
      
      developer.log(
        '🔵 allPointsOfSaleProvider: ${posRecords.length} enregistrements de points de vente trouvés dans Drift',
        name: 'allPointsOfSaleProvider',
      );
      
      for (final record in posRecords) {
        try {
          final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
          posDataList.add(map);
        } catch (e) {
          developer.log(
            '⚠️ allPointsOfSaleProvider: Erreur parsing record Drift: $e',
            name: 'allPointsOfSaleProvider',
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ allPointsOfSaleProvider: Erreur lors de la récupération depuis Drift: $e',
        name: 'allPointsOfSaleProvider',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    // 2. Si aucun point de vente dans Drift, récupérer depuis Firestore
    if (posDataList.isEmpty) {
      try {
        developer.log(
          '🔵 allPointsOfSaleProvider: Aucun point de vente dans Drift, récupération depuis Firestore',
          name: 'allPointsOfSaleProvider',
        );
        
        final firestore = FirebaseFirestore.instance;
        
        // Pour chaque entreprise, récupérer ses points de vente
        for (final enterpriseId in enterprisesMap.keys) {
          try {
            final posCollection = firestore
                .collection('enterprises')
                .doc(enterpriseId)
                .collection('pointsOfSale');
            
            final posSnapshot = await posCollection.get();
            
            developer.log(
              '🔵 allPointsOfSaleProvider: ${posSnapshot.docs.length} points de vente trouvés dans Firestore pour entreprise $enterpriseId',
              name: 'allPointsOfSaleProvider',
            );
            
            for (final doc in posSnapshot.docs) {
              try {
                final data = doc.data();
                final posData = Map<String, dynamic>.from(data)
                  ..['id'] = doc.id
                  ..['parentEnterpriseId'] = enterpriseId;
                
                posDataList.add(posData);
              } catch (e) {
                developer.log(
                  '⚠️ allPointsOfSaleProvider: Erreur parsing doc Firestore: $e',
                  name: 'allPointsOfSaleProvider',
                );
              }
            }
          } catch (e) {
            developer.log(
              '⚠️ allPointsOfSaleProvider: Erreur récupération POS pour entreprise $enterpriseId: $e',
              name: 'allPointsOfSaleProvider',
            );
          }
        }
      } catch (e, stackTrace) {
        developer.log(
          '⚠️ allPointsOfSaleProvider: Erreur lors de la récupération depuis Firestore: $e',
          name: 'allPointsOfSaleProvider',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    
    developer.log(
      '🔵 allPointsOfSaleProvider: Total de ${posDataList.length} points de vente récupérés (Drift + Firestore)',
      name: 'allPointsOfSaleProvider',
    );
    
    final allPointsOfSale = <Enterprise>[];
    
    // Convertir les points de vente en Enterprise-like objects
    for (final map in posDataList) {
      try {
        final posId = map['id'] as String?;
        
        if (posId == null) {
          developer.log(
            '⚠️ allPointsOfSaleProvider: Point de vente sans ID, ignoré',
            name: 'allPointsOfSaleProvider',
          );
          continue;
        }
        
        final parentEnterpriseId = map['parentEnterpriseId'] as String? ?? 
                                   map['enterpriseId'] as String?;
        
        if (parentEnterpriseId == null) {
          developer.log(
            '⚠️ allPointsOfSaleProvider: Point de vente $posId sans parentEnterpriseId, ignoré',
            name: 'allPointsOfSaleProvider',
          );
          continue;
        }
        
        // Trouver l'entreprise mère
        final parentEnterprise = enterprisesMap[parentEnterpriseId];
        
        if (parentEnterprise == null) {
          developer.log(
            '⚠️ allPointsOfSaleProvider: Entreprise mère non trouvée pour parentEnterpriseId=$parentEnterpriseId',
            name: 'allPointsOfSaleProvider',
          );
          continue;
        }
        
        developer.log(
          '🔵 allPointsOfSaleProvider: Conversion point de vente: id=$posId, name=${map['name']}, parentEnterpriseId=$parentEnterpriseId',
          name: 'allPointsOfSaleProvider',
        );
        
        // Convertir les Timestamp Firestore en DateTime si nécessaire
        DateTime? createdAt;
        DateTime? updatedAt;
        
        if (map['createdAt'] != null) {
          if (map['createdAt'] is Timestamp) {
            createdAt = (map['createdAt'] as Timestamp).toDate();
          } else if (map['createdAt'] is String) {
            createdAt = DateTime.tryParse(map['createdAt'] as String);
          }
        }
        
        if (map['updatedAt'] != null) {
          if (map['updatedAt'] is Timestamp) {
            updatedAt = (map['updatedAt'] as Timestamp).toDate();
          } else if (map['updatedAt'] is String) {
            updatedAt = DateTime.tryParse(map['updatedAt'] as String);
          }
        }
        
        // Créer un Enterprise-like object pour le point de vente
        final posEnterprise = Enterprise(
          id: posId,
          name: (map['name'] as String?) ?? 'Point de vente',
          type: parentEnterprise.type,
          description: 'Point de vente de ${parentEnterprise.name} - ${(map['address'] as String?) ?? ''}',
          address: (map['address'] as String?) ?? '',
          phone: (map['contact'] as String?) ?? '',
          isActive: (map['isActive'] as bool?) ?? true,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
        allPointsOfSale.add(posEnterprise);
        developer.log(
          '✅ allPointsOfSaleProvider: Point de vente ajouté: ${posEnterprise.name}',
          name: 'allPointsOfSaleProvider',
        );
      } catch (e, stackTrace) {
        developer.log(
          '❌ Erreur lors de la conversion d\'un point de vente: $e',
          name: 'allPointsOfSaleProvider',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    
    developer.log(
      '🔵 allPointsOfSaleProvider: Total de ${allPointsOfSale.length} points de vente récupérés',
      name: 'allPointsOfSaleProvider',
    );
    
    return allPointsOfSale;
  },
);

/// Provider combiné pour récupérer entreprises + points de vente
///
/// Retourne une liste combinée avec un flag pour distinguer les points de vente.
/// Combine les entreprises normales avec les points de vente convertis en entreprises.
final enterprisesWithPointsOfSaleProvider = FutureProvider.autoDispose<
    List<({Enterprise enterprise, bool isPointOfSale})>>(
  (ref) async {
    developer.log(
      '🔵 enterprisesWithPointsOfSaleProvider: Début de la combinaison',
      name: 'enterprisesWithPointsOfSaleProvider',
    );
    
    // Récupérer les entreprises normales (sans les points de vente)
    final enterprises = await ref.watch(enterprisesProvider.future);
    
    // Récupérer les points de vente convertis en entreprises
    final pointsOfSale = await ref.watch(allPointsOfSaleProvider.future);
    
    developer.log(
      '🔵 enterprisesWithPointsOfSaleProvider: ${enterprises.length} entreprises, ${pointsOfSale.length} points de vente',
      name: 'enterprisesWithPointsOfSaleProvider',
    );
    
    // Créer un Set des IDs des points de vente pour éviter les doublons
    final posIds = pointsOfSale.map((pos) => pos.id).toSet();
    
    // Combiner les entreprises normales (marquées comme non-points de vente)
    final combined = <({Enterprise enterprise, bool isPointOfSale})>[];
    
    for (final enterprise in enterprises) {
      // Exclure les entreprises qui sont en fait des points de vente
      if (!posIds.contains(enterprise.id)) {
        combined.add((enterprise: enterprise, isPointOfSale: false));
      }
    }
    
    // Ajouter les points de vente (marqués comme points de vente)
    for (final pos in pointsOfSale) {
      combined.add((enterprise: pos, isPointOfSale: true));
      developer.log(
        '🔵 enterprisesWithPointsOfSaleProvider: Point de vente ajouté: ${pos.id} - ${pos.name}',
        name: 'enterprisesWithPointsOfSaleProvider',
      );
    }
    
    // Trier par nom
    combined.sort((a, b) => 
        a.enterprise.name.compareTo(b.enterprise.name));
    
    final posCount = combined.where((item) => item.isPointOfSale).length;
    developer.log(
      '🔵 enterprisesWithPointsOfSaleProvider: Total combiné: ${combined.length} éléments (dont $posCount points de vente)',
      name: 'enterprisesWithPointsOfSaleProvider',
    );
    
    return combined;
  },
);

/// Provider pour récupérer les entreprises par type
///
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final enterprisesByTypeProvider = FutureProvider.autoDispose
    .family<List<Enterprise>, String>(
      (ref, type) =>
          ref.watch(enterpriseControllerProvider).getEnterprisesByType(type),
    );

/// Provider pour récupérer les entreprises par parent et par type (Stream)
///
/// Écoute les changements en temps réel.
final enterprisesByParentAndTypeProvider = StreamProvider.autoDispose
    .family<List<Enterprise>, ({String parentId, EnterpriseType type})>(
      (ref, params) {
        return ref.watch(enterpriseControllerProvider).watchAllEnterprises().map(
          (enterprises) => enterprises
              .where((e) => e.parentEnterpriseId == params.parentId && e.type == params.type)
              .toList()
        );
      },
    );

/// Provider pour récupérer une entreprise par ID
///
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final enterpriseByIdProvider = FutureProvider.autoDispose
    .family<Enterprise?, String>(
      (ref, enterpriseId) => ref
          .watch(enterpriseControllerProvider)
          .getEnterpriseById(enterpriseId),
    );

/// Provider pour surveiller tous les utilisateurs (Stream)
///
/// Utilise le controller pour respecter l'architecture.
final usersProvider = StreamProvider.autoDispose<List<User>>(
  (ref) => ref.watch(userControllerProvider).watchAllUsers(),
);

/// Provider pour rechercher des utilisateurs
///
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
/// Limite les résultats à 100 pour améliorer les performances.
final searchUsersProvider = FutureProvider.autoDispose
    .family<List<User>, String>(
      (ref, query) => ref.watch(userControllerProvider).searchUsers(query),
    );

/// Provider pour surveiller les accès EnterpriseModuleUser (Stream)
///
/// Utilise le controller pour respecter l'architecture.
final enterpriseModuleUsersProvider =
    StreamProvider.autoDispose<List<EnterpriseModuleUser>>(
  (ref) => ref.watch(adminControllerProvider).watchEnterpriseModuleUsers(),
);

/// Provider pour récupérer les accès d'un utilisateur
///
/// Utilise le controller pour respecter l'architecture.
/// AutoDispose pour libérer la mémoire automatiquement.
final userEnterpriseModuleUsersProvider = FutureProvider.autoDispose
    .family<List<EnterpriseModuleUser>, String>(
      (ref, userId) => ref
          .watch(adminControllerProvider)
          .getUserEnterpriseModuleUsers(userId),
    );

/// Provider pour surveiller tous les rôles (Stream)
///
/// Utilise le controller pour respecter l'architecture.
final rolesProvider = StreamProvider.autoDispose<List<UserRole>>(
  (ref) => ref.watch(adminControllerProvider).watchAllRoles(),
);

/// Provider pour les statistiques d'administration (Stream)
///
/// Se met à jour automatiquement quand les données changent.
final adminStatsProvider = StreamProvider.autoDispose<AdminStats>((ref) {
  final enterprisesStream =
      ref.watch(enterpriseControllerProvider).watchAllEnterprises();
  final usersStream = ref.watch(userControllerProvider).watchAllUsers();
  final rolesStream = ref.watch(adminControllerProvider).watchAllRoles();
  final assignmentsStream =
      ref.watch(adminControllerProvider).watchEnterpriseModuleUsers();

  return CombineLatestStream.combine4(
    enterprisesStream,
    usersStream,
    rolesStream,
    assignmentsStream,
    (
      List<Enterprise> enterprises,
      List<User> users,
      List<UserRole> roles,
      List<EnterpriseModuleUser> enterpriseModuleUsers,
    ) {
      // Memoize calculations
      final activeEnterprises = enterprises.where((e) => e.isActive).length;
      final activeUsers = users.where((u) => u.isActive).length;

      final enterprisesByType = <String, int>{};
      for (final type in [
        'eau_minerale',
        'gaz',
        'orange_money',
        'immobilier',
        'boutique',
      ]) {
        enterprisesByType[type] =
            enterprises.where((e) => e.type.id == type).length;
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
});

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

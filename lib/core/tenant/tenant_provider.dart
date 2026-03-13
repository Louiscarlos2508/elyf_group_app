import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/user.dart';
import 'package:elyf_groupe_app/core/repositories/repository_providers.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart' show sharedPreferencesProvider;

const String _activeEnterpriseIdKey = 'active_enterprise_id';

/// Provider pour l'ID de l'entreprise active
///
/// Charge automatiquement la valeur sauvegardée au démarrage.
final activeEnterpriseIdProvider =
    AsyncNotifierProvider<ActiveEnterpriseIdNotifier, String?>(() {
      return ActiveEnterpriseIdNotifier();
    });

/// Notifier pour gérer l'ID de l'entreprise active
///
/// Utilise AsyncNotifier pour gérer le chargement asynchrone depuis SharedPreferences
class ActiveEnterpriseIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getString(_activeEnterpriseIdKey);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> setActiveEnterpriseId(String enterpriseId) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_activeEnterpriseIdKey, enterpriseId);
      state = AsyncValue.data(enterpriseId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearActiveEnterprise() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_activeEnterpriseIdKey);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider pour récupérer l'entreprise active complète
///
/// Combine l'ID sauvegardé avec le repository pour récupérer l'entreprise complète
final activeEnterpriseProvider = FutureProvider<Enterprise?>((ref) async {
  final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);

  return activeEnterpriseIdAsync.when(
    data: (enterpriseId) async {
      if (enterpriseId == null) return null;
      final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
      return enterpriseRepo.getEnterpriseById(enterpriseId);
    },
    loading: () async => null,
    error: (_, __) async => null,
  );
});

/// Notifier pour signaler un changement de tenant en cours (transactionnel)
class SwitchingTenantNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

/// Provider pour signaler un changement de tenant en cours
final isSwitchingTenantProvider = NotifierProvider<SwitchingTenantNotifier, bool>(SwitchingTenantNotifier.new);

/// Provider pour les affectations utilisateur (EnterpriseModuleUser)
///
/// Surveille les affectations en temps réel pour l'utilisateur actuel.
/// NOTE: Ce provider est critique pour le calcul des permissions.
final userAssignmentsProvider = StreamProvider<List<EnterpriseModuleUser>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return Stream.value([]);

  final adminRepo = ref.read(adminRepositoryProvider);
  return adminRepo.watchEnterpriseModuleUsers().map((allAccesses) {
    return allAccesses.where((access) => access.userId == currentUserId).toList();
  });
});

final allEnterprisesStreamProvider = StreamProvider<List<Enterprise>>((ref) {
  final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
  return enterpriseRepo.watchAllEnterprises();
});

/// Provider pour surveiller l'utilisateur actuel dans la base locale (Drift)
final currentUserStreamProvider = StreamProvider<User?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchAllUsers().map((users) {
    return users.where((u) => u.id == userId).firstOrNull;
  });
});

/// Provider pour récupérer les entreprises accessibles à l'utilisateur actuel
///
/// Utilise CombineLatestStream directement sur les repositories pour éviter
/// les rebuilds multiples liés aux nested .when() dans les StreamProviders.
/// La société mère n'est PAS incluse pour les utilisateurs POS uniquement.
final userAccessibleEnterprisesProvider = StreamProvider<List<Enterprise>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final isAdmin = ref.watch(isAdminProvider);

  if (currentUserId == null) return Stream.value([]);

  // Accès direct aux repositories (streams stables — pas de re-emission)
  final adminRepo = ref.watch(adminRepositoryProvider);
  final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  final assignmentsStream = adminRepo
      .watchEnterpriseModuleUsers()
      .map((all) => all.where((a) => a.userId == currentUserId).toList());

  final enterprisesStream = enterpriseRepo.watchAllEnterprises();

  final currentUserStream = userRepo
      .watchAllUsers()
      .map((users) => users.where((u) => u.id == currentUserId).firstOrNull);

  return CombineLatestStream.combine3(
    assignmentsStream,
    enterprisesStream,
    currentUserStream,
    (List<EnterpriseModuleUser> assignments, List<Enterprise> enterprises, User? currentUser) {
      if (isAdmin) {
        return enterprises.where((e) => e.isActive).toList();
      }

      final activeAssignments = assignments.where((a) => a.isActive).toList();

      // On utilise UNIQUEMENT les assignments directs (EnterpriseModuleUser).
      // Le champ user.enterpriseIds est un champ dénormalisé auto-maintenu pour
      // les règles de sécurité Firestore, il inclut aussi les entreprises parentes —
      // il ne doit PAS être utilisé pour déterminer la liste de sélection.
      return enterprises.where((e) {
        if (!e.isActive) return false;
        return activeAssignments.any((a) => a.enterpriseId == e.id);
      }).toList();
    },
  ).distinct((prev, curr) {
    if (prev.length != curr.length) return false;
    for (int i = 0; i < prev.length; i++) {
      if (prev[i].id != curr[i].id) return false;
    }
    return true;
  });
});

/// Provider pour récupérer les modules accessibles à l'utilisateur pour l'entreprise active
///
/// Utilise CombineLatestStream directement sur les repositories pour éviter
/// les rebuilds multiples liés aux nested .when() dans les StreamProviders.
final userAccessibleModulesForActiveEnterpriseProvider = StreamProvider<List<String>>((ref) {
  final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
  final activeEnterpriseId = activeEnterpriseIdAsync.value;
  final isAdmin = ref.watch(isAdminProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (activeEnterpriseId == null || currentUserId == null) return Stream.value([]);

  if (isAdmin) {
    return Stream.value(EnterpriseModule.values.map((m) => m.id).toList());
  }

  // Accès direct aux repositories (streams stables)
  final adminRepo = ref.watch(adminRepositoryProvider);
  final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  final assignmentsStream = adminRepo
      .watchEnterpriseModuleUsers()
      .map((all) => all.where((a) => a.userId == currentUserId).toList());

  final enterprisesStream = enterpriseRepo.watchAllEnterprises();

  final currentUserStream = userRepo
      .watchAllUsers()
      .map((users) => users.where((u) => u.id == currentUserId).firstOrNull);

  return CombineLatestStream.combine3(
    assignmentsStream,
    enterprisesStream,
    currentUserStream,
    (List<EnterpriseModuleUser> userAccesses, List<Enterprise> enterprises, User? currentUser) {
      final moduleIds = <String>{};

      // 1. Accès via "enterpriseIds" du profil (Enterprise Admin)
      if (currentUser != null && currentUser.enterpriseIds.contains(activeEnterpriseId)) {
        final enterprise = enterprises.where((e) => e.id == activeEnterpriseId).firstOrNull;
        if (enterprise != null) {
          moduleIds.add(enterprise.type.module.id);
          if (enterprise.type == EnterpriseType.group) {
            moduleIds.add(EnterpriseModule.group.id);
          }
        }
      }

      // 2. Accès via les assignations explicites (EnterpriseModuleUser)
      // On inclut les accès directs ET les accès via parent (si includesChildren)
      final activeEnterprise = enterprises.where((e) => e.id == activeEnterpriseId).firstOrNull;
      final parentId = activeEnterprise?.parentEnterpriseId;

      for (final access in userAccesses) {
        if (!access.isActive) continue;

        // Accès direct
        if (access.enterpriseId == activeEnterpriseId) {
          moduleIds.add(access.moduleId);
        } 
        // Accès via parent
        else if (parentId != null && access.enterpriseId == parentId && access.includesChildren) {
          moduleIds.add(access.moduleId);
        }
      }

      return moduleIds.toList()..sort();
    },
  ).distinct((prev, curr) {
    if (prev.length != curr.length) return false;
    for (int i = 0; i < prev.length; i++) {
      if (prev[i] != curr[i]) return false;
    }
    return true;
  });
});

/// Provider qui gère la sélection automatique de l'entreprise
///
/// - Si l'utilisateur a plusieurs entreprises : vérifie que l'entreprise active est valide,
///   et la nettoie si elle n'est pas dans la liste des entreprises accessibles
/// - Si l'utilisateur n'a qu'une seule entreprise : sélectionne automatiquement
final autoSelectEnterpriseProvider = FutureProvider<void>((ref) async {
  final accessibleEnterprisesAsync = ref.watch(
    userAccessibleEnterprisesProvider,
  );
  final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);

  return accessibleEnterprisesAsync.when(
    data: (enterprises) async {
      // Si la liste est vide, on ne fait rien pour l'instant (peut être transitoire au démarrage)
      if (enterprises.isEmpty) return;

      final currentActiveId = activeEnterpriseIdAsync.when(
        data: (id) => id,
        loading: () => null,
        error: (_, __) => null,
      );

      final notifier = ref.read(activeEnterpriseIdProvider.notifier);

      // Vérifier que l'entreprise active est valide (dans la liste des entreprises accessibles)
      String? validActiveId = currentActiveId;
      if (currentActiveId != null) {
        final isValidEnterprise = enterprises.any(
          (enterprise) => enterprise.id == currentActiveId,
        );
        if (!isValidEnterprise) {
          // L'entreprise active n'est pas valide, la nettoyer
          await notifier.clearActiveEnterprise();
          validActiveId = null;
        }
      }

      // Si l'utilisateur n'a qu'une seule entreprise, sélectionner automatiquement
      if (enterprises.length == 1) {
        if (validActiveId == null) {
          await notifier.setActiveEnterpriseId(enterprises.first.id);
        }
      }
    },
    loading: () async {},
    error: (_, __) async {},
  );
});

/// Modèle pour représenter une hiérarchie d'entreprises
class EnterpriseHierarchyNode {
  final Enterprise enterprise;
  final List<EnterpriseHierarchyNode> children;

  EnterpriseHierarchyNode({
    required this.enterprise,
    this.children = const [],
  });
}

/// Provider pour récupérer les entreprises organisées par module et par hiérarchie
final hierarchicalEnterprisesProvider =
    FutureProvider<Map<EnterpriseModule, List<EnterpriseHierarchyNode>>>((
      ref,
    ) async {
      final accessibleEnterprisesAsync = ref.watch(
        userAccessibleEnterprisesProvider,
      );

      return accessibleEnterprisesAsync.when(
        data: (enterprises) {
          if (enterprises.isEmpty) return {};

          // 1. Groupement par module
          final modulesMap = <EnterpriseModule, List<Enterprise>>{};
          for (final enterprise in enterprises) {
            final module = enterprise.type.module;
            modulesMap.putIfAbsent(module, () => []).add(enterprise);
          }

          final result = <EnterpriseModule, List<EnterpriseHierarchyNode>>{};

          // 2. Pour chaque module, construire la hiérarchie
          for (final module in modulesMap.keys) {
            final moduleEnterprises = modulesMap[module]!;
            final enterpriseIds =
                moduleEnterprises.map((e) => e.id).toSet();
            
            // Identifier les racines de ce module (ceux dont le parent n'est pas accessible ou inexistant)
            final roots = moduleEnterprises.where((e) {
              return e.parentEnterpriseId == null ||
                  !enterpriseIds.contains(e.parentEnterpriseId);
            }).toList();

            final nodes = roots.map((root) {
              return _buildHierarchy(root, moduleEnterprises);
            }).toList();

            result[module] = nodes;
          }

          return result;
        },
        loading: () => {},
        error: (_, __) => {},
      );
    });

/// Fonction récursive pour construire la hiérarchie
EnterpriseHierarchyNode _buildHierarchy(
  Enterprise parent,
  List<Enterprise> allAvailable,
) {
  final children = allAvailable
      .where((e) => e.parentEnterpriseId == parent.id)
      .map((child) => _buildHierarchy(child, allAvailable))
      .toList();

  return EnterpriseHierarchyNode(enterprise: parent, children: children);
}

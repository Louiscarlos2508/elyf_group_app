import 'dart:convert';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../auth/entities/enterprise_module_user.dart';
import '../../features/administration/domain/entities/enterprise.dart';
import '../../features/administration/application/providers.dart';
import '../logging/app_logger.dart';
import '../offline/providers.dart' show sharedPreferencesProvider, driftServiceProvider;
import '../offline/drift/app_database.dart';

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
      return await enterpriseRepo.getEnterpriseById(enterpriseId);
    },
    loading: () async => null,
    error: (_, __) async => null,
  );
});

/// Provider pour les affectations utilisateur (EnterpriseModuleUser)
///
/// Surveille les affectations en temps réel pour l'utilisateur actuel
final userAssignmentsProvider = StreamProvider<List<EnterpriseModuleUser>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return Stream.value([]);

  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.watchEnterpriseModuleUsers().map((allAccesses) {
    return allAccesses.where((access) => access.userId == currentUserId).toList();
  });
});

/// Provider pour toutes les entreprises (normales + points de vente)
///
/// Surveille les deux collections d'entreprises en temps réel
final allEnterprisesStreamProvider = StreamProvider<List<Enterprise>>((ref) {
  final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
  final driftService = ref.watch(driftServiceProvider);

  // Écouter les entreprises normales
  final enterprisesStream = enterpriseRepo.watchAllEnterprises();

  // Sous-entités (Dépôts, Points de vente, Usines, etc. considérés comme des espaces dans le sélecteur)
  // On surveille TOUS les espaces, quel que soit le module
  final subEntitiesStream = driftService.db.watchRecordsByCollection('pointOfSale');

  return Rx.combineLatest2<List<Enterprise>, List<OfflineRecord>, List<Enterprise>>(
    enterprisesStream,
    subEntitiesStream,
    (enterprises, subEntityRecords) {
      final all = <Enterprise>[...enterprises];
      
      // Convertir les records de sous-entités en objets Enterprise
      for (final record in subEntityRecords) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(record.dataJson));
          
          final id = record.remoteId ?? record.localId;
          final name = map['name'] as String? ?? 'Espace sans nom';
          final parentId = map['parentEnterpriseId'] as String? ?? map['enterpriseId'] as String?;
          final parent = enterprises.where((e) => e.id == parentId).firstOrNull;
          
          EnterpriseType childType = EnterpriseType.pointOfSale;
          if (map['type'] != null) {
            childType = EnterpriseType.fromId(map['type'] as String);
          } else if (parent != null) {
            if (parent.type.isGas) {
              childType = EnterpriseType.gasPointOfSale;
            } else if (parent.type.isWater) {
              childType = EnterpriseType.waterPointOfSale;
            } else if (parent.type.isShop) {
              childType = EnterpriseType.shopBranch;
            } else if (parent.type.isMobileMoney) {
              childType = EnterpriseType.mobileMoneyKiosk;
            } else if (parent.type.isRealEstate) {
              childType = EnterpriseType.realEstateBranch;
            }
          }

          all.add(Enterprise(
            id: id,
            name: name,
            type: childType,
            parentEnterpriseId: parentId,
            description: map['description'] as String? ?? map['address'] as String?,
            isActive: map['isActive'] as bool? ?? true,
          ));
        } catch (e) {
          AppLogger.error('allEnterprisesStreamProvider: error parsing sub-entity: $e', name: 'tenant');
        }
      }
      
      // Dédupliquer par ID au cas où
      final unique = <String, Enterprise>{};
      for (final ent in all) {
        unique[ent.id] = ent;
      }
      final result = unique.values.toList();
      return result;
    },
  );
});

/// Provider pour récupérer les entreprises accessibles à l'utilisateur actuel
///
/// Récupère toutes les entreprises où l'utilisateur a un accès actif.
/// Désormais réactif aux changements d'affectation et d'entreprise.
final userAccessibleEnterprisesProvider = StreamProvider<List<Enterprise>>((ref) {
  final assignmentsAsync = ref.watch(userAssignmentsProvider);
  final enterprisesAsync = ref.watch(allEnterprisesStreamProvider);

  return assignmentsAsync.when(
    data: (assignments) {
      return enterprisesAsync.when(
        data: (enterprises) {
          final activeAssignments = assignments.where((a) => a.isActive).toList();
          
          final accessible = enterprises.where((e) {
            if (!e.isActive) return false;

            // 1. Accès direct
            final hasDirectAccess = activeAssignments.any((a) => a.enterpriseId == e.id);
            if (hasDirectAccess) return true;

            // 2. Accès via parent (hiérarchique) avec héritage (includesChildren)
            String? currentParentId = e.parentEnterpriseId;
            while (currentParentId != null) {
              // Vérifier si l'utilisateur a un accès à ce parent avec héritage activé
              final hasParentAccessWithInheritance = activeAssignments.any(
                (a) => a.enterpriseId == currentParentId && a.includesChildren,
              );
              
              if (hasParentAccessWithInheritance) return true;
              
              // Continuer à remonter la hiérarchie
              final parentDoc = enterprises.where((ent) => ent.id == currentParentId).firstOrNull;
              currentParentId = parentDoc?.parentEnterpriseId;
            }

            return false;
          }).toList();
          
          return Stream.value(accessible);
        },
        loading: () => const Stream.empty(),
        error: (e, s) => Stream.error(e, s),
      );
    },
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

/// Provider pour récupérer les modules accessibles à l'utilisateur pour l'entreprise active
///
/// Désormais réactif aux changements d'affectation via userAssignmentsProvider.
final userAccessibleModulesForActiveEnterpriseProvider = StreamProvider<List<String>>((
  ref,
) {
  // Récupérer l'entreprise active
  final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
  final activeEnterpriseId = activeEnterpriseIdAsync.value;

  if (activeEnterpriseId == null) return Stream.value([]);

  // Surveiller les accès via userAssignmentsProvider
  final assignmentsAsync = ref.watch(userAssignmentsProvider);

  return assignmentsAsync.when(
    data: (userAccesses) {
      // Filtrer les accès actifs pour l'entreprise active
      final activeAccesses = userAccesses
          .where(
            (access) =>
                access.enterpriseId == activeEnterpriseId && access.isActive,
          )
          .toList();

      final moduleIds = activeAccesses
          .map((access) => access.moduleId)
          .toSet()
          .toList();

      return Stream.value(moduleIds);
    },
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
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

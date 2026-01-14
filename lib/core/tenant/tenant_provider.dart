import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/providers.dart';
import '../auth/entities/enterprise_module_user.dart';
import '../../features/administration/domain/entities/enterprise.dart';
import '../../features/administration/application/providers.dart';

/// Classe helper pour gérer la persistance de l'entreprise active
class ActiveEnterpriseIdManager {
  static const String _key = 'active_enterprise_id';

  static Future<String?> loadSavedEnterpriseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> saveEnterpriseId(String enterpriseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, enterpriseId);
  }

  static Future<void> clearEnterpriseId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

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
      final savedId = await ActiveEnterpriseIdManager.loadSavedEnterpriseId();
      return savedId;
    } catch (error) {
      // Re-throw pour que AsyncNotifier gère l'erreur automatiquement
      rethrow;
    }
  }

  Future<void> setActiveEnterpriseId(String enterpriseId) async {
    try {
      await ActiveEnterpriseIdManager.saveEnterpriseId(enterpriseId);
      state = AsyncValue.data(enterpriseId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearActiveEnterprise() async {
    try {
      await ActiveEnterpriseIdManager.clearEnterpriseId();
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

/// Provider pour récupérer les entreprises accessibles à l'utilisateur actuel
///
/// Récupère toutes les entreprises où l'utilisateur a un accès actif
final userAccessibleEnterprisesProvider = FutureProvider<List<Enterprise>>((
  ref,
) async {
  // Récupérer l'ID de l'utilisateur connecté depuis l'auth
  final currentUserId = ref.watch(currentUserIdProvider);

  // Si aucun utilisateur n'est connecté, retourner une liste vide
  if (currentUserId == null) {
    return [];
  }

  final adminRepo = ref.watch(adminRepositoryProvider);
  final enterpriseController = ref.watch(enterpriseControllerProvider);

  // Récupérer tous les accès de l'utilisateur
  final userAccesses = await adminRepo.getUserEnterpriseModuleUsers(
    currentUserId,
  );

  // Filtrer uniquement les accès actifs et récupérer les entreprises uniques
  final activeEnterpriseIds = userAccesses
      .where((access) => access.isActive)
      .map((access) => access.enterpriseId)
      .toSet();

  // Récupérer les entreprises correspondantes via le controller (qui déduplique)
  final allEnterprises = await enterpriseController.getAllEnterprises();

  // Filtrer les entreprises accessibles et actives, puis dédupliquer par ID
  final accessibleEnterprises = allEnterprises
      .where(
        (enterprise) =>
            activeEnterpriseIds.contains(enterprise.id) && enterprise.isActive,
      )
      .toList();

  // Dédupliquer par ID pour éviter les doublons (double sécurité)
  final uniqueEnterprises = <String, Enterprise>{};
  for (final enterprise in accessibleEnterprises) {
    if (!uniqueEnterprises.containsKey(enterprise.id)) {
      uniqueEnterprises[enterprise.id] = enterprise;
    }
  }

  return uniqueEnterprises.values.toList();
});

/// Provider pour récupérer les modules accessibles à l'utilisateur pour l'entreprise active
///
/// Filtre les modules selon les accès EnterpriseModuleUser ET vérifie que l'utilisateur
/// a au moins la permission viewDashboard pour chaque module.
///
/// Inclut un mécanisme de retry pour attendre que la synchronisation initiale
/// soit terminée si les données ne sont pas encore disponibles.
final userAccessibleModulesForActiveEnterpriseProvider = FutureProvider<List<String>>((
  ref,
) async {
  // Récupérer l'ID de l'utilisateur connecté
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  // Récupérer l'entreprise active
  final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
  final activeEnterpriseId = activeEnterpriseIdAsync.when(
    data: (id) => id,
    loading: () => null,
    error: (_, __) => null,
  );

  if (activeEnterpriseId == null) return [];

  // Récupérer les accès utilisateur pour l'entreprise active avec retry
  // pour attendre que la synchronisation soit terminée
  final adminRepo = ref.watch(adminRepositoryProvider);
  List<EnterpriseModuleUser> userAccesses = [];

  // Essayer de récupérer les données avec retry (maximum 3 tentatives)
  int maxRetries = 3;
  int retryCount = 0;
  Duration retryDelay = const Duration(milliseconds: 500);

  while (retryCount < maxRetries) {
    try {
      userAccesses = await adminRepo.getUserEnterpriseModuleUsers(
        currentUserId,
      );

      // Si on a des données, on arrête le retry
      if (userAccesses.isNotEmpty || retryCount == maxRetries - 1) {
        break;
      }

      // Attendre un peu avant de réessayer (données pas encore synchronisées)
      await Future.delayed(retryDelay);
      retryCount++;
      retryDelay = Duration(
        milliseconds: retryDelay.inMilliseconds * 2,
      ); // Exponential backoff
    } catch (e) {
      // Si c'est la dernière tentative, on retourne ce qu'on a
      if (retryCount == maxRetries - 1) {
        break;
      }
      await Future.delayed(retryDelay);
      retryCount++;
      retryDelay = Duration(milliseconds: retryDelay.inMilliseconds * 2);
    }
  }

  // Filtrer les accès actifs pour l'entreprise active
  // Même logique que dans login_screen.dart : si l'utilisateur a un EnterpriseModuleUser
  // actif pour cette entreprise et ce module, il a accès au module.
  // La vérification des permissions détaillées se fait au niveau du module.
  final activeAccesses = userAccesses
      .where(
        (access) =>
            access.enterpriseId == activeEnterpriseId && access.isActive,
      )
      .toList();

  // Retourner directement les modules pour lesquels l'utilisateur a un accès actif
  // (sans vérification de permissions détaillées, comme dans login_screen.dart)
  final accessibleModuleIds = activeAccesses
      .map((access) => access.moduleId)
      .toSet()
      .toList();

  return accessibleModuleIds;
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

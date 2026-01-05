import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/providers.dart';
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
final activeEnterpriseIdProvider = AsyncNotifierProvider<ActiveEnterpriseIdNotifier, String?>(() {
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
final userAccessibleEnterprisesProvider = FutureProvider<List<Enterprise>>((ref) async {
  // Récupérer l'ID de l'utilisateur connecté depuis l'auth
  final currentUserId = ref.watch(currentUserIdProvider);
  
  // Si aucun utilisateur n'est connecté, retourner une liste vide
  if (currentUserId == null) {
    return [];
  }
  
  final adminRepo = ref.watch(adminRepositoryProvider);
  final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
  
  // Récupérer tous les accès de l'utilisateur
  final userAccesses = await adminRepo.getUserEnterpriseModuleUsers(currentUserId);
  
  // Filtrer uniquement les accès actifs et récupérer les entreprises uniques
  final activeEnterpriseIds = userAccesses
      .where((access) => access.isActive)
      .map((access) => access.enterpriseId)
      .toSet();
  
  // Récupérer les entreprises correspondantes
  final allEnterprises = await enterpriseRepo.getAllEnterprises();
  return allEnterprises
      .where((enterprise) => 
          activeEnterpriseIds.contains(enterprise.id) && enterprise.isActive)
      .toList();
});

/// Provider qui gère la sélection automatique de l'entreprise
/// 
/// Si l'utilisateur n'a qu'une seule entreprise accessible et qu'aucune
/// entreprise n'est sélectionnée, sélectionne automatiquement cette entreprise.
final autoSelectEnterpriseProvider = FutureProvider<void>((ref) async {
  final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);
  final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
  
  return accessibleEnterprisesAsync.when(
    data: (enterprises) async {
      // Sélection automatique si l'utilisateur n'a qu'une seule entreprise
      if (enterprises.length == 1) {
        final currentActiveId = activeEnterpriseIdAsync.when(
          data: (id) => id,
          loading: () => null,
          error: (_, __) => null,
        );
        
        // Si aucune entreprise n'est sélectionnée, sélectionner automatiquement la seule disponible
        if (currentActiveId == null) {
          final notifier = ref.read(activeEnterpriseIdProvider.notifier);
          await notifier.setActiveEnterpriseId(enterprises.first.id);
        }
      }
    },
    loading: () async {},
    error: (_, __) async {},
  );
});

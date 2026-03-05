import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart' as offline_providers;
import 'package:elyf_groupe_app/core/offline/sync/sync_orchestrator.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

/// Notifier pour gérer le changement de tenant (entreprise active)
class TenantSwitchManager extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initialisation
  }

  /// Déclenche un changement de tenant transactionnel et déterministe
  Future<bool> switchTenant(String enterpriseId) async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;
    
    if (currentUser == null) {
      AppLogger.error('Cannot switch tenant: No authenticated user', name: 'tenant.switch');
      return false;
    }

    state = const AsyncValue.loading();

    try {
      // 0. Activer le flag de changement (verrouille le router et affiche l'overlay)
      ref.read(isSwitchingTenantProvider.notifier).toggle(true);
      AppLogger.info('Starting deterministic switch to enterprise: $enterpriseId', name: 'tenant.switch');

      // 1. Arrêter les flux de synchronisation actuels de manière propre
      final syncOrchestrator = ref.read(syncOrchestratorProvider);
      await syncOrchestrator.stop();

      // 2. Pré-charger les métadonnées critiques du nouveau tenant (Enterprise doc + Assignments + Roles)
      // Cela évite l'écran "Accès restreint" car les données seront là avant le premier rebuild.
      final firestoreSync = ref.read(offline_providers.firestoreSyncServiceProvider);
      
      AppLogger.info('Pre-fetching critical metadata for $enterpriseId...', name: 'tenant.switch');
      // On force la synchronisation du document enterprise, des assignations et des rôles.
      await firestoreSync.syncTenantMetadata(enterpriseId, currentUser.id);
      
      // 3. Invalider les providers liés au tenant pour préparer le nettoyage
      _invalidateTenantScopedProviders();

      // 4. Mettre à jour l'ID de l'entreprise active (persistent)
      // On le fait APRES avoir récupéré les permissions pour que le premier rebuild de l'UI
      // trouve déjà les données nécessaires en base locale.
      final activeIdNotifier = ref.read(activeEnterpriseIdProvider.notifier);
      await activeIdNotifier.setActiveEnterpriseId(enterpriseId);

      // 5. Redémarrer les flux de sync pour le nouveau tenant
      await syncOrchestrator.start(currentUser);
      
      // Attendre que le pull initial soit fini (pour les données temps-réel admin)
      await ref.read(offline_providers.realtimeSyncServiceProvider).waitForInitialPull();

      AppLogger.info('Deterministic switch completed successfully', name: 'tenant.switch');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to switch tenant transactionally', error: e, stackTrace: st, name: 'tenant.switch');
      state = AsyncValue.error(e, st);
      return false;
    } finally {
      // 6. Lever le flag (déverrouille le router)
      ref.read(isSwitchingTenantProvider.notifier).toggle(false);
    }
  }

  void _invalidateTenantScopedProviders() {
    // Invalider les providers qui dépendent de l'ID de l'entreprise active
    // Cela force leur recalcul avec les nouvelles données synchronisées.
    ref.invalidate(activeEnterpriseProvider);
    ref.invalidate(userAccessibleModulesForActiveEnterpriseProvider);
    
    // On pourrait aussi invalider d'autres providers globaux si nécessaire
    AppLogger.info('Tenant-scoped providers invalidated', name: 'tenant.switch');
  }
}

/// Provider pour le gestionnaire de changement de tenant
final tenantSwitchManagerProvider =
    AsyncNotifierProvider<TenantSwitchManager, void>(() {
  return TenantSwitchManager();
});

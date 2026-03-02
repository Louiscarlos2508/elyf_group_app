import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/entities/app_user.dart';
import '../../logging/app_logger.dart';
import '../drift_service.dart';
import '../module_data_sync_service.dart';
import '../sync_paths.dart';
import '../providers.dart' as offline_providers;
import '../../../features/administration/application/providers.dart' as admin_providers;

/// Orchestre la synchronisation des données en fonction du cycle de vie.
class SyncOrchestrator {
  SyncOrchestrator({
    required this.ref,
  });

  final Ref ref;
  
  void start(AppUser user) {
    AppLogger.info('SyncOrchestrator: Starting synchronization flows', name: 'sync.orchestrator');
    
    try {
      final realtimeSyncService = ref.read(offline_providers.realtimeSyncServiceProvider);
      realtimeSyncService.startRealtimeSync(userId: user.id);
    } catch (e) {
      AppLogger.error('Failed to start admin realtime sync', error: e, name: 'sync.orchestrator');
    }

    _syncUserModulesInBackground(user.id).catchError((error) {
       AppLogger.warning('Background module sync failed, but proceeding: $error', name: 'sync.orchestrator');
    });
  }

  void stop() {
    AppLogger.info('SyncOrchestrator: Stopping all sync flows', name: 'sync.orchestrator');
    
    try {
      ref.read(offline_providers.realtimeSyncServiceProvider).stopRealtimeSync();
      ref.read(offline_providers.globalModuleRealtimeSyncServiceProvider).stopAllRealtimeSync();
    } catch (e) {
      AppLogger.error('Error stopping sync flows on logout', error: e, name: 'sync.orchestrator');
    }
  }

  Future<void> _syncUserModulesInBackground(String userId) async {
    if (kIsWeb) return;

    try {
      AppLogger.info('Starting background bootstrap for user $userId', name: 'sync.orchestrator');

      await ref.read(offline_providers.realtimeSyncServiceProvider).waitForInitialPull();

      final adminController = ref.read(admin_providers.adminControllerProvider);
      final userAccesses = await adminController.getUserEnterpriseModuleUsers(userId);
      final activeAccesses = userAccesses.where((access) => access.isActive).toList();

      if (activeAccesses.isEmpty) {
        AppLogger.info('No active modules found for background sync', name: 'sync.orchestrator');
        return;
      }

      final syncService = ModuleDataSyncService(
        firestore: FirebaseFirestore.instance,
        driftService: DriftService.instance,
        collectionPaths: collectionPaths,
      );
      
      final globalModuleSync = ref.read(offline_providers.globalModuleRealtimeSyncServiceProvider);

      for (final access in activeAccesses) {
        try {
          await ref.read(offline_providers.firestoreSyncServiceProvider).syncSpecificEnterprise(access.enterpriseId);
          
          String? parentEnterpriseId;
          try {
            final enterprise = await adminController.getEnterpriseById(access.enterpriseId);
            if (enterprise != null && 
                enterprise.type.name == 'gasPointOfSale' && 
                enterprise.parentEnterpriseId != null) {
              parentEnterpriseId = enterprise.parentEnterpriseId;
              AppLogger.info('Detected POS, adding parent enterprise $parentEnterpriseId to bootstrap', name: 'sync.orchestrator');
              await ref.read(offline_providers.firestoreSyncServiceProvider).syncSpecificEnterprise(parentEnterpriseId!);
            }
          } catch (e) {
            AppLogger.warning('Could not check for parent enterprise: $e', name: 'sync.orchestrator');
          }

          await syncService.syncModuleData(
            enterpriseId: access.enterpriseId,
            moduleId: access.moduleId,
          );
          
          if (parentEnterpriseId != null) {
            await syncService.syncModuleData(
              enterpriseId: parentEnterpriseId,
              moduleId: access.moduleId,
            );
          }
          
          await globalModuleSync.startRealtimeSync(
            enterpriseId: access.enterpriseId,
            moduleId: access.moduleId,
          );
          
          if (parentEnterpriseId != null) {
            await globalModuleSync.startRealtimeSync(
              enterpriseId: parentEnterpriseId,
              moduleId: access.moduleId,
            );
          }
          
          AppLogger.info('Bootstrap completed for module ${access.moduleId} in enterprise ${access.enterpriseId}', name: 'sync.orchestrator');
        } catch (e) {
          AppLogger.warning('Failed to sync module ${access.moduleId}: $e', name: 'sync.orchestrator');
        }
      }

      AppLogger.info('Full bootstrap completed for user $userId', name: 'sync.orchestrator');
    } catch (e, st) {
      AppLogger.error('Critical error during background bootstrap', error: e, stackTrace: st, name: 'sync.orchestrator');
    }
  }
}

/// Provider pour l'orchestrateur de synchronisation.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(ref: ref);
});

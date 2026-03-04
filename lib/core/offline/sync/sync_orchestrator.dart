import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/entities/app_user.dart';
import '../../logging/app_logger.dart';
import '../drift_service.dart';
import '../module_data_sync_service.dart';
import '../sync_paths.dart';
import '../providers.dart' as offline_providers;
import '../../../features/administration/application/providers.dart' as admin_providers;
import '../../tenant/tenant_provider.dart';

/// Orchestre la synchronisation des données en fonction du cycle de vie.
class SyncOrchestrator {
  SyncOrchestrator({
    required this.ref,
  });

  final Ref ref;
  bool _isStopping = false;
  bool _isRunning = false;
  int _currentSessionId = 0;

  Future<void> start(AppUser user) async {
    if (_isRunning) {
      AppLogger.warning('SyncOrchestrator: Synchronization already running. Incrementing session to abort previous flow.', name: 'sync.orchestrator');
      await stop();
    }
    
    _currentSessionId++;
    final sessionId = _currentSessionId;
    
    _isStopping = false;
    _isRunning = true;
    AppLogger.info('SyncOrchestrator: Starting synchronization flows (Session $sessionId)', name: 'sync.orchestrator');
    
    try {
      final realtimeSyncService = ref.read(offline_providers.realtimeSyncServiceProvider);
      await realtimeSyncService.startRealtimeSync(userId: user.id);
    } catch (e) {
      AppLogger.error('Failed to start admin realtime sync', error: e, name: 'sync.orchestrator');
    }

    _syncUserModulesInBackground(user.id, sessionId).then((_) {
      if (sessionId == _currentSessionId) {
        _isRunning = false;
        AppLogger.info('SyncOrchestrator: Background synchronization completed (Session $sessionId)', name: 'sync.orchestrator');
      }
    }).catchError((error) {
       if (sessionId == _currentSessionId) {
         _isRunning = false;
         AppLogger.warning('SyncOrchestrator: Background module sync failed (Session $sessionId): $error', name: 'sync.orchestrator');
       }
    });
  }

  Future<void> stop() async {
    _isStopping = true;
    _currentSessionId++; // Invalidate stale background tasks
    AppLogger.info('SyncOrchestrator: Stopping all sync flows (New session: $_currentSessionId)', name: 'sync.orchestrator');
    
    try {
      await ref.read(offline_providers.realtimeSyncServiceProvider).stopRealtimeSync();
      await ref.read(offline_providers.globalModuleRealtimeSyncServiceProvider).stopAllRealtimeSync();
    } catch (e) {
      AppLogger.error('Error stopping sync flows', error: e, name: 'sync.orchestrator');
    }
  }

  /// S'assure que la synchronisation d'un module spécifique est active pour l'entreprise courante.
  /// Seule autorité pour démarrer une synchronisation de module en temps réel.
  Future<void> ensureModuleSync(String moduleId) async {
    if (_isStopping) return;

    final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value;
    if (activeEnterpriseId == null) {
      AppLogger.warning('SyncOrchestrator: Cannot ensure module sync, no active enterprise ID', name: 'sync.orchestrator');
      return;
    }

    final globalModuleSync = ref.read(offline_providers.globalModuleRealtimeSyncServiceProvider);
    
    // Vérifier si déjà en train d'écouter pour éviter des appels inutiles
    if (globalModuleSync.isListeningTo(activeEnterpriseId, moduleId)) {
      return;
    }

    AppLogger.info('SyncOrchestrator: Ensuring realtime sync for module $moduleId in enterprise $activeEnterpriseId', name: 'sync.orchestrator');

    try {
      final adminController = ref.read(admin_providers.adminControllerProvider);
      final enterprise = await adminController.getEnterpriseById(activeEnterpriseId);
      final parentEnterpriseId = enterprise?.parentEnterpriseId;

      if (_isStopping) return;

      await globalModuleSync.startRealtimeSync(
        enterpriseId: activeEnterpriseId,
        moduleId: moduleId,
        parentEnterpriseId: parentEnterpriseId,
      );
    } catch (e) {
      AppLogger.error('SyncOrchestrator: Failed to ensure module sync for $moduleId', error: e, name: 'sync.orchestrator');
    }
  }

  Future<void> _syncUserModulesInBackground(String userId, int sessionId) async {
    if (kIsWeb) return;

    try {
      AppLogger.info('Starting background bootstrap (Session $sessionId)', name: 'sync.orchestrator');

      // Wait for initial pull (admin data)
      await ref.read(offline_providers.realtimeSyncServiceProvider).waitForInitialPull();
      
      if (_isStopping || sessionId != _currentSessionId) {
        AppLogger.info('SyncOrchestrator: Aborting background bootstrap (stale session $sessionId)', name: 'sync.orchestrator');
        return;
      }

      final adminController = ref.read(admin_providers.adminControllerProvider);
      final userAccesses = await adminController.getUserEnterpriseModuleUsers(userId);
      
      // Filtrer pour ne synchroniser que le tenant ACTIF
      final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value;
      if (activeEnterpriseId == null) {
        AppLogger.warning('SyncOrchestrator: No active enterprise ID for background sync', name: 'sync.orchestrator');
        return;
      }

      final activeAccesses = userAccesses.where((access) => 
        access.isActive && access.enterpriseId == activeEnterpriseId
      ).toList();

      if (activeAccesses.isEmpty) {
        AppLogger.info('SyncOrchestrator: No active modules found for $activeEnterpriseId in background', name: 'sync.orchestrator');
        return;
      }

      final syncService = ModuleDataSyncService(
        firestore: FirebaseFirestore.instance,
        driftService: DriftService.instance,
        collectionPaths: collectionPaths,
      );
      
      for (final access in activeAccesses) {
        if (_isStopping || sessionId != _currentSessionId || FirebaseAuth.instance.currentUser == null) {
          return;
        }

        try {
          // Sync metadata for enterprise and parent
          await ref.read(offline_providers.firestoreSyncServiceProvider).syncSpecificEnterprise(access.enterpriseId);
          
          if (_isStopping || sessionId != _currentSessionId) return;

          String? parentEnterpriseId;
          try {
            final enterprise = await adminController.getEnterpriseById(access.enterpriseId);
            if (enterprise != null && enterprise.parentEnterpriseId != null) {
              parentEnterpriseId = enterprise.parentEnterpriseId;
              
              if (_isStopping || sessionId != _currentSessionId || FirebaseAuth.instance.currentUser == null) return;
              await ref.read(offline_providers.firestoreSyncServiceProvider).syncSpecificEnterprise(parentEnterpriseId!);
            }
          } catch (e) {
            AppLogger.warning('Could not check for parent enterprise: $e', name: 'sync.orchestrator');
          }

          if (_isStopping || sessionId != _currentSessionId || FirebaseAuth.instance.currentUser == null) return;

          // Perform one-time data sync for the module
          await syncService.syncModuleData(
            enterpriseId: access.enterpriseId,
            moduleId: access.moduleId,
            parentEnterpriseId: parentEnterpriseId,
          );
          
          if (_isStopping || sessionId != _currentSessionId || FirebaseAuth.instance.currentUser == null) return;

          // Start realtime sync through the consolidated authority
          await ensureModuleSync(access.moduleId);
          
        } catch (e) {
          AppLogger.warning('Failed to sync module ${access.moduleId}: $e', name: 'sync.orchestrator');
        }
      }
    } catch (e, st) {
      AppLogger.error('Critical error during background bootstrap', error: e, stackTrace: st, name: 'sync.orchestrator');
    }
  }
}

/// Provider pour l'orchestrateur de synchronisation.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(ref: ref);
});

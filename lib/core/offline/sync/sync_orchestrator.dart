import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/entities/app_user.dart';
import '../../auth/providers.dart' as auth_providers;
import '../../logging/app_logger.dart';
import '../drift_service.dart';
import '../module_data_sync_service.dart';
import '../sync_paths.dart';
import '../providers.dart' as offline_providers;
import '../sync/sync_push_service.dart';
import '../../../features/administration/application/providers.dart' as admin_providers;
import '../../../features/administration/domain/entities/enterprise.dart';
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
  StreamSubscription<SyncTriggerEvent>? _pushSubscription;

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
      
      // Listen for reactive sync pushes (Silent Pushes)
      _pushSubscription?.cancel();
      _pushSubscription = SyncPushService.instance.syncTriggers.listen((event) {
        _handleSyncTrigger(event, user.id);
      });
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
      
      await _pushSubscription?.cancel();
      _pushSubscription = null;
    } catch (e) {
      AppLogger.error('Error stopping sync flows', error: e, name: 'sync.orchestrator');
    }
  }

  /// S'assure que la synchronisation d'un module spécifique est active pour l'entreprise cible.
  /// Seule autorité pour démarrer une synchronisation de module en temps réel.
  Future<void> ensureModuleSync(String moduleId, {String? enterpriseId}) async {
    if (_isStopping) return;

    final targetEnterpriseId = enterpriseId ?? ref.read(activeEnterpriseIdProvider).value;
    if (targetEnterpriseId == null) {
      AppLogger.warning('SyncOrchestrator: Cannot ensure module sync, no active enterprise ID', name: 'sync.orchestrator');
      return;
    }

    final globalModuleSync = ref.read(offline_providers.globalModuleRealtimeSyncServiceProvider);
    
    AppLogger.info('SyncOrchestrator: Ensuring realtime sync for module $moduleId in enterprise $targetEnterpriseId', name: 'sync.orchestrator');

    try {
      final adminController = ref.read(admin_providers.adminControllerProvider);
      
      // Get the enterprise and its hierarchy info
      final enterprise = await adminController.getEnterpriseById(targetEnterpriseId);
      final parentEnterpriseId = enterprise?.parentEnterpriseId;

      if (_isStopping) return;

      // Start realtime sync for the main enterprise
      if (!globalModuleSync.isListeningTo(targetEnterpriseId, moduleId)) {
        await globalModuleSync.startRealtimeSync(
          enterpriseId: targetEnterpriseId,
          moduleId: moduleId,
          parentEnterpriseId: parentEnterpriseId,
        );
      }

      // Check if we should also sync children for this user/module combo
      final isAdmin = ref.read(auth_providers.isAdminProvider);
      final authService = ref.read(auth_providers.authServiceProvider);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        bool hasIncludesChildrenAccess = isAdmin;

        if (!hasIncludesChildrenAccess) {
          final assignments = await adminController.getUserEnterpriseModuleUsers(currentUser.id);
          // Check if any assignment for THIS enterprise and THIS module has includesChildren
          hasIncludesChildrenAccess = assignments.any((a) => 
            a.enterpriseId == targetEnterpriseId && 
            a.moduleId == moduleId && 
            a.isActive && 
            a.includesChildren
          );
        }

        if (hasIncludesChildrenAccess) {
          AppLogger.info('SyncOrchestrator: Parent access detected, synchronizing child enterprises for module $moduleId', name: 'sync.orchestrator');
          final enterpriseController = ref.read(admin_providers.enterpriseControllerProvider);
          final allEnterprises = await enterpriseController.getAllEnterprises();
          final children = allEnterprises.where((e) => e.parentEnterpriseId == targetEnterpriseId).toList();
          
          for (final child in children) {
            if (_isStopping) break;
            if (!globalModuleSync.isListeningTo(child.id, moduleId)) {
              await globalModuleSync.startRealtimeSync(
                enterpriseId: child.id,
                moduleId: moduleId,
                parentEnterpriseId: targetEnterpriseId, // Active parent
              );
            }
          }
        }
      }
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

      // Récupérer l'entreprise active pour vérifier la hiérarchie
      final enterpriseController = ref.read(admin_providers.enterpriseControllerProvider);
      final activeEnterprise = await enterpriseController.getEnterpriseById(activeEnterpriseId);
      final parentEnterpriseId = activeEnterprise?.parentEnterpriseId;

      final isAdmin = ref.read(auth_providers.isAdminProvider);
      final authService = ref.read(auth_providers.authServiceProvider);
      final currentUser = authService.currentUser;

      final Set<String> modulesToSync = {};

      if (isAdmin) {
        // Un admin système synchronise tous les modules disponibles
        modulesToSync.addAll(EnterpriseModule.values.map((m) => m.id));
      } else {
        // 1. Accès directs à l'entreprise active
        for (final access in userAccesses) {
          if (access.isActive && access.enterpriseId == activeEnterpriseId) {
            modulesToSync.add(access.moduleId);
          }
        }

        // 2. Accès hiérarchiques (via parent avec includesChildren)
        if (parentEnterpriseId != null) {
          for (final access in userAccesses) {
            if (access.isActive && 
                access.enterpriseId == parentEnterpriseId && 
                access.includesChildren) {
              modulesToSync.add(access.moduleId);
            }
          }
        }

        // 3. Accès via enterpriseIds dénormalisés (Enterprise Admin)
        if (currentUser != null && 
            currentUser.enterpriseIds.contains(activeEnterpriseId) && 
            activeEnterprise != null) {
          modulesToSync.add(activeEnterprise.type.module.id);
          // Special case for groups
          if (activeEnterprise.type == EnterpriseType.group) {
            modulesToSync.add(EnterpriseModule.group.id);
          }
        }
      }

      if (modulesToSync.isEmpty) {
        AppLogger.info('SyncOrchestrator: No active modules found for $activeEnterpriseId in background', name: 'sync.orchestrator');
        return;
      }

      final syncService = ModuleDataSyncService(
        firestore: FirebaseFirestore.instance,
        driftService: DriftService.instance,
        collectionPaths: collectionPaths,
      );

      final firestoreSync = ref.read(offline_providers.firestoreSyncServiceProvider);
      
      // Expand accesses to include children if necessary for each module
      final List<({String enterpriseId, String moduleId, String? parentEnterpriseId})> syncQueue = [];

      for (final moduleId in modulesToSync) {
        // Direct sync for active enterprise
        syncQueue.add((
          enterpriseId: activeEnterpriseId,
          moduleId: moduleId,
          parentEnterpriseId: parentEnterpriseId,
        ));

        // Hierarchical sync for children if user has parent access with includesChildren OR is Admin
        bool shouldSyncChildren = isAdmin;
        if (!shouldSyncChildren) {
          shouldSyncChildren = userAccesses.any((a) => 
            a.enterpriseId == activeEnterpriseId && 
            a.moduleId == moduleId && 
            a.isActive && 
            a.includesChildren
          );
        }

        if (shouldSyncChildren) {
          AppLogger.info('SyncOrchestrator: Parent access or Admin detected for module $moduleId, discovering and syncing child enterprises', name: 'sync.orchestrator');
          
          if (activeEnterprise != null) {
            await firestoreSync.discoverSubTenants(activeEnterpriseId);
            // Refresh enterprises list after discovery
            final updatedEnterprises = await enterpriseController.getAllEnterprises();
            final children = updatedEnterprises.where((e) => e.parentEnterpriseId == activeEnterpriseId);
            
            for (final child in children) {
              syncQueue.add((
                enterpriseId: child.id,
                moduleId: moduleId,
                parentEnterpriseId: activeEnterpriseId,
              ));
            }
          }
        }
      }
      
      for (final target in syncQueue) {
        if (_isStopping || sessionId != _currentSessionId || FirebaseAuth.instance.currentUser == null) {
          return;
        }

        try {
          // Sync metadata for enterprise
          await ref.read(offline_providers.firestoreSyncServiceProvider).syncSpecificEnterprise(target.enterpriseId);
          
          if (_isStopping || sessionId != _currentSessionId) return;

          // If we reach here, we've already synced target.enterpriseId metadata.
          // Now perform one-time data sync for the module
          await syncService.syncModuleData(
            enterpriseId: target.enterpriseId,
            moduleId: target.moduleId,
            parentEnterpriseId: target.parentEnterpriseId,
          );
          
          if (_isStopping || sessionId != _currentSessionId || FirebaseAuth.instance.currentUser == null) return;

          // Start realtime sync through the consolidated authority
          await ensureModuleSync(target.moduleId);
          
        } catch (e) {
          AppLogger.warning('Failed to sync module ${target.moduleId} for enterprise ${target.enterpriseId}: $e', name: 'sync.orchestrator');
        }
      }
    } catch (e, st) {
      AppLogger.error('Critical error during background bootstrap', error: e, stackTrace: st, name: 'sync.orchestrator');
    }
  }

  /// Traite un événement de déclenchement de synchronisation reçu par Push.
  Future<void> _handleSyncTrigger(SyncTriggerEvent event, String userId) async {
    AppLogger.info('SyncOrchestrator: Handling push sync trigger: $event', name: 'sync.orchestrator');
    
    final sessionId = _currentSessionId;
    
    try {
      if (event.type == SyncTriggerType.module && event.moduleId != null) {
        // Déclencher une récupération spécifique pour le module
        await _syncModuleOnTrigger(event.moduleId!, event.enterpriseId, sessionId);
      } else {
        // Déclencher une synchronisation globale (bootstrap partiel)
        await _syncUserModulesInBackground(userId, sessionId);
      }
    } catch (e) {
      AppLogger.warning('Failed to handle sync trigger: $e', name: 'sync.orchestrator');
    }
  }

  Future<void> _syncModuleOnTrigger(String moduleId, String? enterpriseId, int sessionId) async {
     // Si une entreprise spécifique est ciblée, on s'assure qu'elle est sync
     // Sinon on utilise l'entreprise active si le module correspond
     final activeEnterpriseId = ref.read(activeEnterpriseIdProvider).value;
     final targetEnterpriseId = enterpriseId ?? activeEnterpriseId;
     
     if (targetEnterpriseId == null) return;

     AppLogger.info('Triggering pull sync for module $moduleId in enterprise $targetEnterpriseId', name: 'sync.orchestrator');

     final syncService = ModuleDataSyncService(
        firestore: FirebaseFirestore.instance,
        driftService: DriftService.instance,
        collectionPaths: collectionPaths,
        syncManager: ref.read(offline_providers.syncManagerProvider),
      );

      // Perform one-time data sync for the module
      await syncService.syncModuleData(
        enterpriseId: targetEnterpriseId,
        moduleId: moduleId,
        essentialOnly: false, // Push triggers usually mean something specific changed, pull all for that module
      );
      
      // Ensure realtime listeners are also alive
      await ensureModuleSync(moduleId);
  }
}

/// Provider pour l'orchestrateur de synchronisation.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(ref: ref);
});

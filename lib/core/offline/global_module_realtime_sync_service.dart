import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'drift_service.dart';
import 'module_realtime_sync_service.dart';
import 'sync_manager.dart';

/// Service global pour la synchronisation en temps réel de tous les modules.
///
/// Gère la synchronisation en temps réel de plusieurs modules simultanément,
/// contrairement à ModuleRealtimeSyncService qui ne gère qu'un seul module à la fois.
///
/// Les changements Firestore → local sont synchronisés automatiquement pour tous
/// les modules auxquels l'utilisateur a accès.
///
/// Gère les conflits pour éviter d'écraser les modifications locales
/// non synchronisées.
class GlobalModuleRealtimeSyncService {
  GlobalModuleRealtimeSyncService({
    required this.firestore,
    required this.driftService,
    required this.collectionPaths,
    SyncManager? syncManager,
    ConflictResolver? conflictResolver,
  })  : _syncManager = syncManager,
        _conflictResolver = conflictResolver ?? const ConflictResolver();

  final FirebaseFirestore firestore;
  final DriftService driftService;
  final SyncManager? _syncManager;
  final ConflictResolver _conflictResolver;
  final Map<String, String Function(String p1)> collectionPaths;

  // Map pour stocker les services de sync par module/entreprise
  final Map<String, ModuleRealtimeSyncService> _syncServices = {};

  /// Démarre la synchronisation en temps réel pour un module.
  ///
  /// Si la synchronisation est déjà active pour ce module, ne fait rien.
  Future<void> startRealtimeSync({
    required String enterpriseId,
    required String moduleId,
  }) async {
    final key = '$enterpriseId/$moduleId';

    // Vérifier si la sync est déjà active
    if (_syncServices.containsKey(key)) {
      final existingService = _syncServices[key]!;
      if (existingService.isListeningTo(enterpriseId, moduleId)) {
        developer.log(
          'Realtime sync already active for module $moduleId in enterprise $enterpriseId',
          name: 'global.module.sync',
        );
        return;
      }
    }

    try {
      developer.log(
        'Starting realtime sync for module $moduleId in enterprise $enterpriseId',
        name: 'global.module.sync',
      );

      final syncService = ModuleRealtimeSyncService(
        firestore: firestore,
        driftService: driftService,
        syncManager: _syncManager,
        conflictResolver: _conflictResolver,
        collectionPaths: collectionPaths,
      );

      await syncService.startRealtimeSync(
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      _syncServices[key] = syncService;

      developer.log(
        'Realtime sync started for module $moduleId in enterprise $enterpriseId',
        name: 'global.module.sync',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error starting realtime sync for module $moduleId: $e',
        name: 'global.module.sync',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - continuer avec les autres modules
    }
  }

  /// Arrête la synchronisation en temps réel pour un module spécifique.
  Future<void> stopRealtimeSync({
    required String enterpriseId,
    required String moduleId,
  }) async {
    final key = '$enterpriseId/$moduleId';
    final syncService = _syncServices[key];

    if (syncService != null) {
      try {
        await syncService.stopRealtimeSync();
        _syncServices.remove(key);
        developer.log(
          'Realtime sync stopped for module $moduleId in enterprise $enterpriseId',
          name: 'global.module.sync',
        );
      } catch (e, stackTrace) {
        developer.log(
          'Error stopping realtime sync for module $moduleId: $e',
          name: 'global.module.sync',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Arrête toutes les synchronisations en temps réel.
  Future<void> stopAllRealtimeSync() async {
    developer.log(
      'Stopping all realtime syncs (${_syncServices.length} active)',
      name: 'global.module.sync',
    );

    final futures = <Future<void>>[];
    for (final entry in _syncServices.entries) {
      futures.add(entry.value.stopRealtimeSync());
    }

    await Future.wait(futures);
    _syncServices.clear();

    developer.log(
      'All realtime syncs stopped',
      name: 'global.module.sync',
    );
  }

  /// Vérifie si la synchronisation est active pour un module.
  bool isListeningTo(String enterpriseId, String moduleId) {
    final key = '$enterpriseId/$moduleId';
    final syncService = _syncServices[key];
    return syncService?.isListeningTo(enterpriseId, moduleId) ?? false;
  }

  /// Retourne le nombre de modules actuellement synchronisés.
  int get activeSyncCount => _syncServices.length;
}

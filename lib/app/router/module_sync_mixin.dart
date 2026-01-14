import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/drift_service.dart';
import '../../core/offline/module_realtime_sync_service.dart';

/// Mixin pour déclencher la synchronisation en temps réel lors de l'accès à un module.
///
/// Utilisé par les RouteWrappers pour démarrer la synchronisation en temps réel
/// des données d'un module depuis Firestore vers Drift.
///
/// Gère automatiquement le démarrage et l'arrêt de la synchronisation
/// pour éviter les fuites mémoire et les race conditions.
mixin ModuleSyncMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  ModuleRealtimeSyncService? _realtimeSyncService;
  String? _lastEnterpriseId;
  String? _lastModuleId;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    stopModuleSync();
    super.dispose();
  }

  /// Arrête la synchronisation en temps réel.
  ///
  /// Appelé automatiquement dans dispose() pour éviter les fuites mémoire.
  void stopModuleSync() {
    if (_realtimeSyncService != null) {
      _realtimeSyncService!
          .stopRealtimeSync()
          .catchError((error) {
            developer.log(
              'Error stopping module sync: $error',
              name: 'module.sync.mixin',
              error: error,
            );
          })
          .whenComplete(() {
            _realtimeSyncService = null;
            _lastEnterpriseId = null;
            _lastModuleId = null;
          });
    }
  }

  /// Déclenche la synchronisation en temps réel des données du module.
  ///
  /// Utilise un callback post-frame pour éviter les appels dans build()
  /// et vérifie que le widget est toujours monté avant de démarrer.
  ///
  /// [enterpriseId] : ID de l'entreprise active
  /// [moduleId] : ID du module à synchroniser
  void startModuleSync(String enterpriseId, String moduleId) {
    // Ne pas démarrer si le widget est déjà disposé
    if (_isDisposed) {
      return;
    }

    // Arrêter la sync précédente si on change de module/entreprise
    if (_realtimeSyncService != null &&
        (_lastEnterpriseId != enterpriseId || _lastModuleId != moduleId)) {
      stopModuleSync();
      // Attendre un peu pour que l'arrêt se termine
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSyncSafely(enterpriseId, moduleId);
      });
      return;
    }

    // Vérifier si on est déjà en train d'écouter ce module
    if (_realtimeSyncService?.isListeningTo(enterpriseId, moduleId) ?? false) {
      return;
    }

    // Utiliser addPostFrameCallback pour éviter d'appeler dans build()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSyncSafely(enterpriseId, moduleId);
    });
  }

  /// Démarre la synchronisation de manière sûre en vérifiant que le widget est monté.
  void _startSyncSafely(String enterpriseId, String moduleId) {
    // Vérifier que le widget est toujours monté
    if (_isDisposed || !mounted) {
      return;
    }

    // Vérifier à nouveau si on est déjà en train d'écouter
    if (_realtimeSyncService?.isListeningTo(enterpriseId, moduleId) ?? false) {
      return;
    }

    _lastEnterpriseId = enterpriseId;
    _lastModuleId = moduleId;

    // Créer et démarrer le service de synchronisation en temps réel
    _realtimeSyncService = ModuleRealtimeSyncService(
      firestore: FirebaseFirestore.instance,
      driftService: DriftService.instance,
    );

    // Démarrer la sync de manière asynchrone et vérifier mounted après
    _realtimeSyncService!
        .startRealtimeSync(enterpriseId: enterpriseId, moduleId: moduleId)
        .then((_) {
          if (!mounted || _isDisposed) {
            // Si le widget a été disposé pendant la sync, arrêter immédiatement
            stopModuleSync();
          }
        })
        .catchError((error) {
          developer.log(
            'Error starting module sync: $error',
            name: 'module.sync.mixin',
            error: error,
          );
          // Log l'erreur mais ne bloque pas l'affichage du module
          // Les données locales seront utilisées même si la sync échoue
        });
  }
}

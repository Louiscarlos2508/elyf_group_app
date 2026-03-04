import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_handler.dart';
import '../../core/logging/app_logger.dart';

import '../../core/offline/sync/sync_orchestrator.dart' show syncOrchestratorProvider;
import '../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;

/// Mixin pour déclencher la synchronisation en temps réel lors de l'accès à un module.
///
/// Utilisé par les RouteWrappers pour s'assurer que la synchronisation en temps réel
/// est active pour le module visité.
///
/// Utilise le GlobalModuleRealtimeSyncService pour éviter les duplications.
/// Si la synchronisation est déjà active (démarrée après la connexion), ne fait rien.
///
/// Gère automatiquement le démarrage et l'arrêt de la synchronisation
/// pour éviter les fuites mémoire et les race conditions.
mixin ModuleSyncMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
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
  /// Note: Ne fait rien car la synchronisation est gérée globalement.
  /// La synchronisation reste active même après la navigation pour permettre
  /// la détection des changements Firestore en temps réel.
  ///
  /// Si vous voulez vraiment arrêter la sync, utilisez globalModuleRealtimeSyncService
  /// directement depuis le code qui gère la déconnexion.
  void stopModuleSync() {
    // Ne rien faire - la synchronisation est gérée globalement
    // et doit rester active même après la navigation pour détecter
    // les changements Firestore en temps réel
    _lastEnterpriseId = null;
    _lastModuleId = null;
  }

  /// Déclenche la synchronisation en temps réel des données du module.
  ///
  /// Utilise le GlobalModuleRealtimeSyncService pour éviter les duplications.
  /// Si la synchronisation est déjà active (démarrée après la connexion), ne fait rien.
  ///
  /// Utilise un callback post-frame pour éviter les appels dans build()
  /// et vérifie que le widget est toujours monté avant de démarrer.
  ///
  /// [enterpriseId] : ID de l'entreprise active
  /// [moduleId] : ID du module à synchroniser
  void startModuleSync(String enterpriseId, String moduleId) {
    // Ne pas démarrer si le widget est déjà disposed
    if (_isDisposed) {
      return;
    }

    // Si on change de module/entreprise, mettre à jour les références
    if (_lastEnterpriseId != enterpriseId || _lastModuleId != moduleId) {
      _lastEnterpriseId = enterpriseId;
      _lastModuleId = moduleId;
    }

    // Utiliser addPostFrameCallback pour éviter d'appeler dans build()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSyncSafely(enterpriseId, moduleId);
    });
  }

  /// Démarre la synchronisation de manière sûre en vérifiant que le widget est monté.
  ///
  /// Utilise le GlobalModuleRealtimeSyncService pour éviter les duplications.
  /// Si la synchronisation est déjà active, ne fait rien.
  void _startSyncSafely(String enterpriseId, String moduleId) {
    // Vérifier que le widget est toujours monté
    if (_isDisposed || !mounted) {
      return;
    }

    // Vérifier si le service global est disponible via Riverpod
    final syncOrchestrator = ref.read(syncOrchestratorProvider);

    // Déléguer la synchronisation à l'orchestrateur (autorité unique)
    // Il gérera le filtrage par entreprise active et la résolution du parent.
    syncOrchestrator
        .ensureModuleSync(moduleId)
        .then((_) {
          if (!mounted || _isDisposed) {
            developer.log(
              'Widget disposed during sync start, but sync will continue globally',
              name: 'module.sync.mixin',
            );
          } else {
            developer.log(
              'Realtime sync requested for module $moduleId (delegated to orchestrator)',
              name: 'module.sync.mixin',
            );
          }
        })
        .catchError((error, stackTrace) {
          final appException = ErrorHandler.instance.handleError(error, stackTrace);
          AppLogger.warning(
            'Error requesting module sync from orchestrator: ${appException.message}',
            name: 'module.sync.mixin',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }
}

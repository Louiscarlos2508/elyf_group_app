import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_handler.dart';
import '../../core/logging/app_logger.dart';

import '../../app/bootstrap.dart' show globalModuleRealtimeSyncService;

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

    // Vérifier si le service global est disponible
    final globalSync = globalModuleRealtimeSyncService;
    if (globalSync == null) {
      developer.log(
        'GlobalModuleRealtimeSyncService not available, skipping sync',
        name: 'module.sync.mixin',
      );
      return;
    }

    // Vérifier si la synchronisation est déjà active pour ce module
    // Cela évite les duplications : si la sync a été démarrée après la connexion,
    // elle est déjà active et on ne fait rien
    if (globalSync.isListeningTo(enterpriseId, moduleId)) {
      developer.log(
        'Realtime sync already active for module $moduleId in enterprise $enterpriseId',
        name: 'module.sync.mixin',
      );
      return;
    }

    // Démarrer la synchronisation via le service global
    // Cela évite les duplications car le service global vérifie déjà
    // si une sync est active avant de démarrer
    globalSync
        .startRealtimeSync(enterpriseId: enterpriseId, moduleId: moduleId)
        .then((_) {
          if (!mounted || _isDisposed) {
            developer.log(
              'Widget disposed during sync start, but sync will continue globally',
              name: 'module.sync.mixin',
            );
          } else {
            developer.log(
              'Realtime sync started/verified for module $moduleId in enterprise $enterpriseId',
              name: 'module.sync.mixin',
            );
          }
        })
        .catchError((error, stackTrace) {
          final appException = ErrorHandler.instance.handleError(error, stackTrace);
          AppLogger.warning(
            'Error starting module sync: ${appException.message}',
            name: 'module.sync.mixin',
            error: error,
            stackTrace: stackTrace,
          );
          // Log l'erreur mais ne bloque pas l'affichage du module
          // Les données locales seront utilisées même si la sync échoue
        });
  }
}

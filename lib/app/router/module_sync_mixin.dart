import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/drift_service.dart';
import '../../core/offline/module_realtime_sync_service.dart';

/// Mixin pour déclencher la synchronisation en temps réel lors de l'accès à un module.
///
/// Utilisé par les RouteWrappers pour démarrer la synchronisation en temps réel
/// des données d'un module depuis Firestore vers Drift.
mixin ModuleSyncMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  ModuleRealtimeSyncService? _realtimeSyncService;
  String? _lastEnterpriseId;
  String? _lastModuleId;

  /// Arrête la synchronisation en temps réel.
  ///
  /// À appeler depuis dispose() du widget parent si nécessaire.
  void stopModuleSync() {
    _realtimeSyncService?.stopRealtimeSync().catchError((error) {
      // Ignorer les erreurs lors de l'arrêt
    });
    _realtimeSyncService = null;
  }

  /// Déclenche la synchronisation en temps réel des données du module.
  ///
  /// [enterpriseId] : ID de l'entreprise active
  /// [moduleId] : ID du module à synchroniser
  void startModuleSync(String enterpriseId, String moduleId) {
    // Arrêter la sync précédente si on change de module/entreprise
    if (_realtimeSyncService != null &&
        (_lastEnterpriseId != enterpriseId || _lastModuleId != moduleId)) {
      _realtimeSyncService?.stopRealtimeSync().catchError((error) {
        // Ignorer les erreurs lors de l'arrêt
      });
      _realtimeSyncService = null;
    }

    // Vérifier si on est déjà en train d'écouter ce module
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

    _realtimeSyncService!
        .startRealtimeSync(enterpriseId: enterpriseId, moduleId: moduleId)
        .catchError((error) {
          // Log l'erreur mais ne bloque pas l'affichage du module
          // Les données locales seront utilisées même si la sync échoue
        });
  }
}

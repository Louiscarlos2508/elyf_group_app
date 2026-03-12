import 'dart:async';
import '../../logging/app_logger.dart';

/// Type de déclencheur de synchronisation.
enum SyncTriggerType {
  /// Synchronisation d'un module spécifique.
  module,
  
  /// Synchronisation globale.
  global,
}

/// Événement de déclenchement de synchronisation.
class SyncTriggerEvent {
  SyncTriggerEvent({
    required this.type,
    this.moduleId,
    this.enterpriseId,
  });

  final SyncTriggerType type;
  final String? moduleId;
  final String? enterpriseId;

  @override
  String toString() => 'SyncTriggerEvent(type: $type, moduleId: $moduleId, enterpriseId: $enterpriseId)';
}

/// Service pour collecter les signaux de synchronisation (Push, UI, etc.)
/// et les diffuser aux orchestrateurs intéressés.
class SyncPushService {
  SyncPushService._();
  
  static final SyncPushService _instance = SyncPushService._();
  static SyncPushService get instance => _instance;

  final _syncTriggerController = StreamController<SyncTriggerEvent>.broadcast();

  /// Stream des événements de synchronisation.
  Stream<SyncTriggerEvent> get syncTriggers => _syncTriggerController.stream;

  /// Déclenche une synchronisation suite à un signal externe.
  void triggerSync({
    SyncTriggerType type = SyncTriggerType.global,
    String? moduleId,
    String? enterpriseId,
  }) {
    final event = SyncTriggerEvent(
      type: type,
      moduleId: moduleId,
      enterpriseId: enterpriseId,
    );
    
    AppLogger.info('Triggering sync event: $event', name: 'sync.push_service');
    _safeAdd(event);
  }

  void _safeAdd(SyncTriggerEvent event) {
    if (!_syncTriggerController.isClosed) {
      _syncTriggerController.add(event);
    }
  }

  /// Ferme le stream.
  void dispose() {
    _syncTriggerController.close();
  }
}

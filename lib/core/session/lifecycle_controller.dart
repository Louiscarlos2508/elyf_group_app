import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';
import '../offline/sync/sync_orchestrator.dart';
import 'session_manager.dart';
import 'session_state.dart';

/// Contrôleur central du cycle de vie de l'application.
class AppLifecycleController {
  AppLifecycleController(this.ref) {
    _init();
  }

  final Ref ref;
  bool _isSyncRunning = false;

  void _init() {
    AppLogger.info('Initializing AppLifecycleController', name: 'lifecycle.controller');
    
    // Écouter les changements d'état de la session
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      _handleStateChange(previous, next);
    }, fireImmediately: true);
  }

  void _handleStateChange(SessionState? previous, SessionState next) {
    AppLogger.debug('Lifecycle state transition: ${previous?.runtimeType} -> ${next.runtimeType}', name: 'lifecycle.controller');

    if (next is AuthenticatedSession) {
      _startAuthenticatedFlows(next);
    } else if (next is UnauthenticatedSession) {
      _stopAuthenticatedFlows();
    }
  }

  void _startAuthenticatedFlows(AuthenticatedSession session) {
    if (_isSyncRunning) {
      AppLogger.info('Sync already running, skipping redundant start', name: 'lifecycle.controller');
      return;
    }

    AppLogger.info('Starting authenticated lifecycle flows for user ${session.user.id}', name: 'lifecycle.controller');
    
    final syncOrchestrator = ref.read(syncOrchestratorProvider);
    syncOrchestrator.start(session.user);
    
    _isSyncRunning = true;
  }

  void _stopAuthenticatedFlows() {
    if (!_isSyncRunning) return;

    AppLogger.info('Stopping authenticated lifecycle flows', name: 'lifecycle.controller');
    
    final syncOrchestrator = ref.read(syncOrchestratorProvider);
    syncOrchestrator.stop();
    
    _isSyncRunning = false;
  }
}

/// Provider pour le contrôleur de cycle de vie.
final appLifecycleControllerProvider = Provider<AppLifecycleController>((ref) {
  return AppLifecycleController(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_manager.dart';
import 'session_state.dart';

export 'session_manager.dart' show sessionManagerProvider;
export 'session_state.dart';
export 'lifecycle_controller.dart' show appLifecycleControllerProvider;
export '../offline/sync/sync_orchestrator.dart' show syncOrchestratorProvider;

/// Provider unifié pour l'état de la session (lecture seule).
final sessionStateProvider = Provider<SessionState>((ref) {
  return ref.watch(sessionManagerProvider);
});

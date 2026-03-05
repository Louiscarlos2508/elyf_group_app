import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/entities/app_user.dart';
import '../auth/providers.dart';
import '../logging/app_logger.dart';
import '../tenant/tenant_provider.dart';
import 'session_state.dart';

/// Gère le cycle de vie de la session applicative.
class SessionManager extends Notifier<SessionState> {
  @override
  SessionState build() {
    // Écouter les changements d'utilisateur via le provider existant
    ref.listen<AsyncValue<AppUser?>>(currentUserProvider, (previous, next) {
      next.when(
        data: _handleUserChange,
        error: (e, st) => state = SessionError(e.toString()),
        loading: () {},
      );
    });

    // État initial basé sur la valeur actuelle de currentUserProvider
    final currentUser = ref.read(currentUserProvider);
    return currentUser.when(
      data: (AppUser? user) => user == null ? const UnauthenticatedSession() : LoadingContextSession(user),
      error: (e, st) => SessionError(e.toString()),
      loading: () => const AuthenticatingSession(),
    );
  }

  void _handleUserChange(AppUser? user) async {
    if (user == null) {
      if (state is! UnauthenticatedSession) {
        AppLogger.info('User logged out, clearing session and enterprise context', name: 'session.manager');
        
        try {
          await ref.read(activeEnterpriseIdProvider.notifier).clearActiveEnterprise();
        } catch (e) {
          AppLogger.error('Error clearing active enterprise on logout', error: e, name: 'session.manager');
        }
        
        state = const UnauthenticatedSession();
      }
      return;
    }

    final currentState = state;
    if (currentState is AuthenticatedSession && currentState.user.id == user.id) {
      return;
    }

    AppLogger.info('User logged in, initializing context for ${user.id}', name: 'session.manager');
    state = LoadingContextSession(user);

    try {
      state = AuthenticatedSession(user);
    } catch (e) {
      AppLogger.error('Failed to initialize session context', error: e, name: 'session.manager');
      state = SessionError('Erreur d\'initialisation du contexte: $e');
    }
  }
}

/// Provider pour gérer la session utilisateur.
final sessionManagerProvider = NotifierProvider<SessionManager, SessionState>(() {
  return SessionManager();
});

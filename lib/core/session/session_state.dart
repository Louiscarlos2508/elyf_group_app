import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/entities/app_user.dart';

/// Les différents états d'une session applicative.
abstract class SessionState {
  const SessionState();
}

/// Session non authentifiée (état initial ou après logout).
class UnauthenticatedSession extends SessionState {
  const UnauthenticatedSession();
}

/// En cours d'authentification.
class AuthenticatingSession extends SessionState {
  const AuthenticatingSession();
}

/// Authentifié, mais le contexte (tenant, etc.) est en cours de chargement.
class LoadingContextSession extends SessionState {
  final AppUser user;
  const LoadingContextSession(this.user);
}

/// Session active et prête à l'emploi.
class AuthenticatedSession extends SessionState {
  final AppUser user;
  const AuthenticatedSession(this.user);
}

/// Erreur lors de l'établissement de la session.
class SessionError extends SessionState {
  final String message;
  final String? code;
  const SessionError(this.message, [this.code]);
}

/// Exception de base pour toutes les exceptions de l'application.
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Exception pour les erreurs de réseau.
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// Exception pour les erreurs d'authentification.
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

/// Exception pour les erreurs d'autorisation.
class AuthorizationException extends AppException {
  const AuthorizationException(super.message, [super.code]);
}

/// Exception pour les erreurs de validation.
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

/// Exception pour les erreurs de données non trouvées.
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.code]);
}

/// Exception pour les erreurs de stockage.
class StorageException extends AppException {
  const StorageException(super.message, [super.code]);
}

/// Exception pour les erreurs de synchronisation.
class SyncException extends AppException {
  const SyncException(super.message, [super.code]);
}

/// Exception pour les erreurs inconnues.
class UnknownException extends AppException {
  const UnknownException(super.message, [super.code]);
}


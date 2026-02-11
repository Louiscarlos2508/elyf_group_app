import 'app_exceptions.dart';

/// Gestionnaire centralisé d'erreurs.
class ErrorHandler {
  ErrorHandler._();

  static final instance = ErrorHandler._();

  /// Convertit une exception en AppException.
  AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    // Gérer les erreurs spécifiques
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return NetworkException(
        'Erreur de connexion réseau. Vérifiez votre connexion internet.',
        'NETWORK_ERROR',
      );
    }

    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized') ||
        errorString.contains('login')) {
      return AuthenticationException(
        'Erreur d\'authentification. Veuillez vous reconnecter.',
        'AUTH_ERROR',
      );
    }

    if (errorString.contains('permission') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied')) {
      return AuthorizationException(
        'Vous n\'avez pas les permissions nécessaires pour cette action.',
        'AUTHZ_ERROR',
      );
    }

    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('format')) {
      return ValidationException(
        'Les données fournies ne sont pas valides.',
        'VALIDATION_ERROR',
      );
    }

    if (errorString.contains('not found') ||
        errorString.contains('404') ||
        errorString.contains('does not exist')) {
      return NotFoundException(
        'La ressource demandée n\'a pas été trouvée.',
        'NOT_FOUND',
      );
    }

    if (errorString.contains('storage') ||
        errorString.contains('database') ||
        errorString.contains('isar')) {
      return StorageException(
        'Erreur de stockage local. Veuillez réessayer.',
        'STORAGE_ERROR',
      );
    }

    if (errorString.contains('sync') ||
        errorString.contains('synchronization')) {
      return SyncException(
        'Erreur de synchronisation. Les données seront synchronisées plus tard.',
        'SYNC_ERROR',
      );
    }

    if (errorString.contains('business') ||
        errorString.contains('insufficient') ||
        errorString.contains('liquidity') ||
        errorString.contains('stock')) {
      return BusinessException(
        errorString.contains('insufficient') ||
                errorString.contains('stock') ||
                errorString.contains('liquidity')
            ? error.toString()
            : 'Une règle métier n\'est pas respectée.',
        'BUSINESS_ERROR',
      );
    }

    // Erreur inconnue
    return UnknownException(
      'Une erreur inattendue s\'est produite. Veuillez réessayer.',
      'UNKNOWN_ERROR',
    );
  }

  /// Obtient un message utilisateur-friendly pour une exception.
  String getUserMessage(AppException exception) {
    return exception.message;
  }

  /// Obtient un titre pour une exception.
  String getErrorTitle(AppException exception) {
    return switch (exception) {
      NetworkException() => 'Erreur de connexion',
      AuthenticationException() => 'Erreur d\'authentification',
      AuthorizationException() => 'Accès refusé',
      ValidationException() => 'Erreur de validation',
      NotFoundException() => 'Non trouvé',
      StorageException() => 'Erreur de stockage',
      SyncException() => 'Erreur de synchronisation',
      BusinessException() => 'Règle métier',
      UnknownException() => 'Erreur',
      _ => 'Erreur',
    };
  }
}

/// Barrel file pour exporter tous les providers et controllers d'authentification.

// Providers du service d'authentification
export 'services/auth_service.dart' show
    authServiceProvider,
    firestoreUserServiceProvider,
    currentUserIdProvider,
    isAuthenticatedProvider,
    currentUserProvider,
    isAdminProvider;

// Controller d'authentification
export 'controllers/auth_controller.dart' show
    authControllerProvider,
    AuthController;


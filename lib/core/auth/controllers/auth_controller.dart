import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/app_exceptions.dart';
import '../../logging/app_logger.dart';
import '../entities/entities.dart';
import '../services/auth_service.dart';
import '../../firebase/firestore_user_service.dart';
import '../../../features/administration/application/controllers/user_controller.dart';
import '../../../features/administration/application/providers.dart'
    show userControllerProvider;
import '../../../features/administration/domain/entities/user.dart';
import '../../offline/sync/sync_orchestrator.dart';

/// Controller pour gérer l'authentification.
///
/// Encapsule la logique métier d'authentification et expose
/// des méthodes simples pour l'UI.
/// 
/// Note: Ce controller ne gère PLUS la synchronisation des données.
/// La synchronisation est orchestrée par [SyncOrchestrator] qui écoute
/// les changements d'état de la session via [SessionManager].
class AuthController {
  AuthController({
    required this.authService,
    required this.firestoreUserService,
    required Ref ref,
    UserController? userController,
  })  : _ref = ref,
        _userController = userController;

  final AuthService authService;
  final FirestoreUserService firestoreUserService;
  final Ref _ref;
  final UserController? _userController;

  /// Se connecter avec email et mot de passe.
  ///
  /// Retourne l'utilisateur connecté ou lance une exception en cas d'erreur.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Connexion avec Firebase Auth
      final user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info(
        'Login successful for user ${user.id}. SessionManager will handle context initialization.',
        name: 'auth.controller',
      );

      return user;
    } catch (e) {
      // Améliorer les messages d'erreur selon le type d'erreur
      final errorString = e.toString().toLowerCase();

      // Erreur réseau
      if (errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated')) {
        throw NetworkException(
          'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne. '
          'Assurez-vous que votre appareil a accès à Internet pour synchroniser les données.',
          'NETWORK_ERROR',
        );
      }

      // Erreur d'initialisation Firebase Core
      if (errorString.contains('notinitializederror') ||
          (errorString.contains('not initialized') &&
              errorString.contains('firebaseapp'))) {
        throw UnknownException(
          'Erreur d\'initialisation : Firebase n\'est pas correctement initialisé. '
          'Veuillez redémarrer l\'application.',
          'FIREBASE_INIT_ERROR',
        );
      }
      rethrow;
    }
  }

  /// Créer le premier utilisateur admin.
  Future<AppUser> createFirstAdmin({
    required String email,
    required String password,
  }) async {
    return await authService.createFirstAdmin(email: email, password: password);
  }

  /// Se déconnecter.
  ///
  /// Nettoie l'état d'authentification de l'utilisateur.
  /// L'arrêt des synchronisations est géré par SyncOrchestrator.
  Future<void> signOut() async {
    AppLogger.info('Logging out user', name: 'auth.controller');
    
    try {
      // 1. Arrêter d'abord les synchronisations pour éviter les PERMISSION_DENIED
      // pendant que le token est encore valide.
      final syncOrchestrator = _ref.read(syncOrchestratorProvider);
      syncOrchestrator.stop();
      AppLogger.info('Sync flows stopped successfully before logout', name: 'auth.controller');
    } catch (e) {
      AppLogger.warning('Failed to stop sync flows during logout: $e', name: 'auth.controller');
    }

    // 2. Déconnexion effective de Firebase
    await authService.signOut();
  }

  /// Recharger l'utilisateur actuel.
  Future<void> reloadUser() async {
    await authService.reloadUser();
  }

  /// Obtenir l'utilisateur actuel.
  AppUser? get currentUser => authService.currentUser;

  /// Vérifier si un utilisateur est connecté.
  bool get isAuthenticated => authService.isAuthenticated;

  /// Change le mot de passe de l'utilisateur actuel.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Met à jour le profil de l'utilisateur actuel.
  Future<void> updateProfile({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    bool isActive = true,
    bool isAdmin = false,
  }) async {
    final userController = _userController;
    if (userController != null) {
      final user = User(
        id: userId,
        email: email,
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        username: username ?? '',
        phone: phone,
        isActive: isActive,
      );
      
      await userController.updateUser(
        user,
        currentUserId: userId,
      );
    } else {
      await firestoreUserService.createOrUpdateUser(
        userId: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        isActive: isActive,
        isAdmin: isAdmin,
      );
    }
  }
}

/// Provider pour le controller d'authentification.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    authService: ref.watch(authServiceProvider),
    firestoreUserService: ref.watch(firestoreUserServiceProvider),
    userController: ref.watch(userControllerProvider),
    ref: ref,
  );
});

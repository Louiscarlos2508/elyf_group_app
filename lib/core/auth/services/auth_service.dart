import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase/firestore_user_service.dart';
import '../entities/app_user.dart';
import 'auth_session_service.dart';
import 'auth_user_service.dart';
import 'auth_storage_service.dart';

/// Service d'authentification avec Firebase Auth et Firestore.
///
/// Orchestrateur principal qui délègue aux sous-services :
/// - `AuthSessionService` : Gestion de session et connexion
/// - `AuthUserService` : Création d'utilisateurs et changement de mot de passe
/// - `AuthStorageService` : Gestion du stockage sécurisé
///
/// Utilise Firebase Auth pour l'authentification et Firestore
/// pour stocker les profils utilisateurs.
///
/// Crée automatiquement le premier utilisateur admin dans Firestore
/// lors de la première connexion si aucun admin n'existe.
class AuthService {
  final AuthSessionService _sessionService;
  final AuthUserService _userService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreUserService? firestoreUserService,
    FirebaseFirestore? firestore,
    AuthStorageService? authStorageService,
    AuthSessionService? authSessionService,
    AuthUserService? authUserService,
  })  : _sessionService = authSessionService ??
            AuthSessionService(
              firebaseAuth: firebaseAuth,
              firestoreUserService: firestoreUserService,
              firestore: firestore,
              authStorageService: authStorageService,
            ),
        _userService = authUserService ??
            AuthUserService(
              firebaseAuth: firebaseAuth,
              firestoreUserService: firestoreUserService,
              firestore: firestore,
              authStorageService: authStorageService,
            );

  /// Initialiser le service (charger l'utilisateur depuis Firebase Auth et Firestore)
  Future<void> initialize() async {
    await _sessionService.initialize();
  }

  /// Se connecter avec email et mot de passe via Firebase Auth.
  ///
  /// Crée automatiquement le premier utilisateur admin dans Firestore
  /// lors de la première connexion si aucun admin n'existe.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _sessionService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Se déconnecter
  Future<void> signOut() async {
    await _sessionService.signOut();
  }

  /// Obtenir l'utilisateur actuel
  AppUser? get currentUser => _sessionService.currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isAuthenticated => _sessionService.isAuthenticated;

  /// Stream de l'utilisateur actuel.
  Stream<AppUser?> get userStream => _sessionService.userStream;

  /// Crée un compte utilisateur normal dans Firebase Auth.
  ///
  /// Cette méthode crée un utilisateur standard (NON admin).
  /// Pour créer un admin, utiliser createFirstAdmin.
  Future<String> createUserAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _userService.createUserAccount(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  /// Crée le premier utilisateur admin dans Firebase Auth et Firestore.
  ///
  /// Cette méthode est appelée lors de la première installation
  /// pour créer le compte admin par défaut uniquement.
  ///
  /// ⚠️ Ne pas utiliser pour créer des utilisateurs normaux.
  Future<AppUser> createFirstAdmin({
    required String email,
    required String password,
  }) async {
    return await _userService.createFirstAdmin(
      email: email,
      password: password,
    );
  }

  /// Change le mot de passe de l'utilisateur actuel.
  ///
  /// Nécessite une ré-authentification avec le mot de passe actuel
  /// pour des raisons de sécurité.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _userService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Force la réinitialisation du service (utile après un clean/rebuild ou en cas de conflit)
  ///
  /// Nettoie toutes les données locales d'authentification et réinitialise l'état.
  /// Cette méthode est utile pour résoudre les conflits entre SecureStorage et Firebase Auth.
  Future<void> forceReset() async {
    await _sessionService.forceReset();
  }

  /// Recharger l'utilisateur depuis le stockage sécurisé
  Future<void> reloadUser() async {
    await _sessionService.reloadUser();
  }
}

/// Provider pour le service Firestore des utilisateurs
final firestoreUserServiceProvider = Provider<FirestoreUserService>((ref) {
  return FirestoreUserService(firestore: FirebaseFirestore.instance);
});

/// Provider pour le service d'authentification
///
/// Le service est initialisé de manière lazy lors du premier accès.
/// L'initialisation est gérée par le provider currentUserProvider qui attend
/// que le service soit initialisé avant de l'utiliser.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firestoreUserService: ref.watch(firestoreUserServiceProvider),
  );
});

/// Provider pour l'utilisateur actuel
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final authService = ref.watch(authServiceProvider);

  // Initialiser si nécessaire
  await authService.initialize();

  // Émettre l'utilisateur actuel initial
  yield authService.currentUser;

  // Émettre les changements futurs
  yield* authService.userStream;
});

/// Provider pour l'ID de l'utilisateur actuel (compatible avec l'existant)
///
/// Utilise ref.watch sur currentUserProvider pour être réactif.
final currentUserIdProvider = Provider<String?>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.maybeWhen(
    data: (user) => user?.id,
    orElse: () => null,
  );
});

/// Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Provider pour vérifier si l'utilisateur est admin
final isAdminProvider = Provider<bool>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.maybeWhen(
    data: (user) => user?.isAdmin ?? false,
    orElse: () => false,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../../firebase/firestore_user_service.dart';

/// Controller pour gérer l'authentification.
/// 
/// Encapsule la logique métier d'authentification et expose
/// des méthodes simples pour l'UI.
class AuthController {
  AuthController({
    required this.authService,
    required this.firestoreUserService,
  });

  final AuthService authService;
  final FirestoreUserService firestoreUserService;

  /// Se connecter avec email et mot de passe.
  /// 
  /// Retourne l'utilisateur connecté ou lance une exception en cas d'erreur.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // Initialiser le service si nécessaire
    await authService.initialize();

    // Connexion avec Firebase Auth
    // Le service crée automatiquement le profil dans Firestore
    // et le premier admin si nécessaire
    final user = await authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return user;
  }

  /// Créer le premier utilisateur admin.
  /// 
  /// Cette méthode est utilisée lors de la première installation
  /// pour créer le compte admin par défaut.
  Future<AppUser> createFirstAdmin({
    required String email,
    required String password,
  }) async {
    return await authService.createFirstAdmin(
      email: email,
      password: password,
    );
  }

  /// Se déconnecter.
  Future<void> signOut() async {
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
}

/// Provider pour le controller d'authentification.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    authService: ref.watch(authServiceProvider),
    firestoreUserService: ref.watch(firestoreUserServiceProvider),
  );
});


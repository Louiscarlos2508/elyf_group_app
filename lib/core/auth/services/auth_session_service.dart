import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, User, UserCredential, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../firebase/firestore_user_service.dart';
import '../../errors/app_exceptions.dart';
import '../../errors/error_handler.dart';
import '../../logging/app_logger.dart';
import '../entities/app_user.dart';
import 'auth_storage_service.dart';

/// Service de gestion de session pour l'authentification.
///
/// Gère l'initialisation, la connexion, la déconnexion,
/// et le rechargement de l'utilisateur.
class AuthSessionService {
  AuthSessionService({
    required FirebaseAuth firebaseAuth,
    required FirestoreUserService firestoreUserService,
    required AuthStorageService authStorageService,
  })  : _firebaseAuth = firebaseAuth,
        _firestoreUserService = firestoreUserService,
        _authStorageService = authStorageService;

  final FirebaseAuth _firebaseAuth;
  final FirestoreUserService _firestoreUserService;
  final AuthStorageService _authStorageService;

  AppUser? _currentUser;
  bool _isInitialized = false;

  /// Stream Controller pour notifier des changements de l'utilisateur.
  final _userStreamController = StreamController<AppUser?>.broadcast();

  /// Stream de l'utilisateur actuel.
  Stream<AppUser?> get userStream => _userStreamController.stream;

  /// Récupère l'email admin depuis les variables d'environnement.
  String get _adminEmail {
    return dotenv.env['ADMIN_EMAIL'] ?? 'admin@elyf.com';
  }

  /// Obtenir l'utilisateur actuel
  AppUser? get currentUser => _currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isAuthenticated => _currentUser != null;

  /// Vérifier si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Initialiser le service (charger l'utilisateur depuis Firebase Auth et Firestore)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Vérifier d'abord si Firebase Core est initialisé
      if (Firebase.apps.isEmpty) {
        AppLogger.info(
          'Firebase Core not initialized - will work in offline mode',
          name: 'auth.session',
        );
        await _loadUserFromStorage();
        _isInitialized = true;
        return;
      }

      // Migrer les données depuis SharedPreferences si nécessaire
      await _authStorageService.migrateFromSharedPreferences();

      await _authStorageService.isLoggedIn();

      // Attendre activement que Firebase Auth restaure l'état
      // Passer de 2s à 5s pour être plus robuste lors des Hot Reloads/Restarts
      User? firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        try {
          AppLogger.debug(
            'Waiting for Firebase Auth to restore session...',
            name: 'auth.session',
          );
          firebaseUser = await _firebaseAuth.authStateChanges().first.timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
        } catch (e) {
          AppLogger.error(
            'Timeout waiting for authStateChanges(): $e',
            name: 'auth.session',
          );
        }
      }

      // Charger l'utilisateur depuis le cache local pour la persistence offline
      final localUser = await _authStorageService.loadUser();

      // LOGIQUE DE SÉCURITÉ CRITIQUE : Vérification de cohérence
      if (firebaseUser != null) {
        AppLogger.info(
          'Firebase Auth confirmed user: ${firebaseUser.email} (${firebaseUser.uid})',
          name: 'auth.session',
        );

        if (localUser != null && localUser.id != firebaseUser.uid) {
          // ALERTE ROUGE : L'ID local ne correspond pas à l'ID Firebase
          // Cela peut arriver après un changement de compte rapide ou un bug de persistence
          AppLogger.warning(
            'SECURITY ALERT: Local ID (${localUser.id}) mismatch with Firebase ID (${firebaseUser.uid}). '
            'Clearing stale local data...',
            name: 'auth.session',
          );
          await _authStorageService.clearLocalAuthData();
        }
        
        // Continuer avec l'utilisateur Firebase (Source de vérité)
        await _fetchAndSyncFirestoreUser(firebaseUser);
      } else {
        // Pas d'utilisateur Firebase trouvé après l'attente
        if (localUser != null) {
          AppLogger.info(
            'No Firebase user found. Falling back to secure local storage for offline access.',
            name: 'auth.session',
          );
          _updateUser(localUser);
        } else {
          AppLogger.info('No user session found (Firebase or Local).', name: 'auth.session');
          _updateUser(null);
        }
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error during auth session initialization: ${appException.message}',
        name: 'auth.session',
        error: e,
        stackTrace: stackTrace,
      );

      // Vérifier si c'est une vraie erreur d'initialisation Firebase Core
      // (pas juste une erreur Firestore, réseau ou de permissions)
      final errorString = e.toString().toLowerCase();
      final isFirebaseCoreError =
          errorString.contains('firebaseapp') &&
          (errorString.contains('not initialized') ||
              errorString.contains('notinitialized') ||
              errorString.contains('no default app'));

      final isNetworkError =
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated');

      if (isFirebaseCoreError) {
        // Firebase Core n'est vraiment pas initialisé - c'est un problème critique
        AppLogger.critical(
          'Firebase Core not initialized - this is a critical error',
          name: 'auth.session',
        );
        throw UnknownException(
          'Firebase n\'est pas initialisé. Veuillez redémarrer l\'application.',
          'FIREBASE_NOT_INITIALIZED',
        );
      } else if (isNetworkError) {
        // Erreur réseau - pas un problème d'initialisation, l'app peut fonctionner en offline
        AppLogger.warning(
          'Network error during auth initialization (offline mode will be used)',
          name: 'auth.session',
        );
        // Ne pas throw - permettre à l'app de continuer en mode offline
        _isInitialized = true;
        return;
      }

      // Pour les autres erreurs (Firestore permissions, timeout, etc.),
      // marquer comme initialisé pour permettre à l'app de continuer
      // L'utilisateur pourra se connecter et les données seront synchronisées
      AppLogger.info(
        'Auth session initialized despite Firestore/network errors (will work on login)',
        name: 'auth.session',
      );
      _isInitialized = true;
      return; // Sortir sans throw pour permettre à l'app de continuer
    }

    _isInitialized = true;
  }

  /// Charge l'utilisateur depuis le stockage sécurisé et met à jour l'état.
  Future<void> _loadUserFromStorage() async {
    final user = await _authStorageService.loadUser();
    _updateUser(user);
  }

  /// Récupère les données Firestore pour un utilisateur Firebase et synchronise le cache local.
  Future<void> _fetchAndSyncFirestoreUser(User firebaseUser) async {
    try {
      // Un court délai pour s'assurer que Firebase est stable
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final userData = await _firestoreUserService
          .getUserById(firebaseUser.uid)
          .timeout(const Duration(seconds: 5));

      AppUser appUser;
      if (userData != null) {
        appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName:
              userData['firstName'] != null && userData['lastName'] != null
              ? '${userData['firstName']} ${userData['lastName']}'
              : userData['username'] as String?,
          isAdmin: userData['isAdmin'] as bool? ?? false,
        );
      } else {
        // Utilisateur Firebase existe mais pas dans Firestore (rare), utiliser les données minimales
        AppLogger.warning(
          'User not found in Firestore, fallback to minimal AppUser',
          name: 'auth.session',
        );
        appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Utilisateur',
          isAdmin: firebaseUser.email?.toLowerCase() == _adminEmail.toLowerCase(),
        );
      }

      // Mise à jour de l'état ET du cache local (Source de vérité synchronisée)
      _updateUser(appUser);
      await _authStorageService.saveUser(appUser);
      
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error syncing Firestore user (offline mode fallback): ${appException.message}',
        name: 'auth.session',
      );
      
      // En cas d'erreur (réseau), on essaie de charger ce qu'on a déjà en cache local
      // SI l'ID correspond, sinon on reste avec les données minimales de Firebase
      final localUser = await _authStorageService.loadUser();
      if (localUser != null && localUser.id == firebaseUser.uid) {
        _updateUser(localUser);
      } else {
        // Fallback minimal
        _updateUser(AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          isAdmin: firebaseUser.email?.toLowerCase() == _adminEmail.toLowerCase(),
        ));
      }
    }
  }

  /// Met à jour l'utilisateur actuel et notifie les écouteurs.
  void _updateUser(AppUser? user) {
    _currentUser = user;
    _userStreamController.add(user);
    AppLogger.debug(
      'Auth user state updated: ${user?.email ?? "null"}',
      name: 'auth.session',
    );
  }

  /// Se connecter avec email et mot de passe via Firebase Auth.
  ///
  /// Crée automatiquement le premier utilisateur admin dans Firestore
  /// lors de la première connexion si aucun admin n'existe.
  ///
  /// Cette méthode est très complexe et gère de nombreux cas d'erreur
  /// pour assurer une expérience utilisateur fluide même en cas de problèmes réseau.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // S'assurer que le service est initialisé
      // Ne pas bloquer la connexion si initialize() échoue - Firebase Auth peut fonctionner quand même
      if (!_isInitialized) {
        try {
          await initialize();
        } catch (e, stackTrace) {
          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          // Si initialize() échoue (réseau, Firestore, etc.), continuer quand même
          // Firebase Auth peut fonctionner indépendamment
          AppLogger.warning(
            'Warning: Auth session initialization failed, but continuing with login: ${appException.message}',
            name: 'auth.session',
            error: e,
            stackTrace: stackTrace,
          );
          // Vérifier si Firebase Auth est disponible quand même
          if (Firebase.apps.isEmpty) {
            throw UnknownException(
              'Firebase n\'est pas initialisé. Veuillez redémarrer l\'application complètement (Stop + Run).',
              'FIREBASE_NOT_INITIALIZED',
            );
          }
          // Vérifier la cohérence : si SecureStorage dit "logged in" mais Firebase Auth n'a pas d'utilisateur,
          // nettoyer pour éviter les conflits lors de la nouvelle connexion
          final isLoggedInLocal = await _authStorageService.isLoggedIn();
          final hasFirebaseUser = _firebaseAuth.currentUser != null;
          if (isLoggedInLocal && !hasFirebaseUser) {
            AppLogger.warning(
              'Inconsistency detected during login: cleaning local auth data',
              name: 'auth.session',
            );
            await _authStorageService.clearLocalAuthData();
          }
          // Marquer comme initialisé pour éviter de réessayer
          _isInitialized = true;
        }
      }

      // Authentifier avec Firebase Auth
      // Note: Les erreurs GoogleApiManager/DEVELOPER_ERROR peuvent apparaître dans les logs
      // mais ne bloquent généralement pas Firebase Auth
      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Gérer les erreurs Firebase Auth avec des messages plus clairs
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage =
                'Aucun compte trouvé avec cet email. Vérifiez que l\'utilisateur existe dans Firebase Console.';
            break;
          case 'wrong-password':
            errorMessage =
                'Mot de passe incorrect. Vérifiez votre mot de passe.';
            break;
          case 'invalid-email':
            errorMessage = 'Format d\'email invalide.';
            break;
          case 'user-disabled':
            errorMessage =
                'Ce compte a été désactivé. Contactez l\'administrateur.';
            break;
          case 'too-many-requests':
            errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
            break;
          case 'operation-not-allowed':
            errorMessage =
                'La connexion par email/mot de passe n\'est pas activée dans Firebase Console.';
            break;
          case 'network-request-failed':
            errorMessage = 'Erreur réseau. Vérifiez votre connexion internet.';
            break;
          case 'invalid-credential':
          case 'credential-already-in-use':
            errorMessage = 'Identifiants invalides. Code d\'erreur: ${e.code}';
            break;
          default:
            errorMessage = 'Erreur d\'authentification: ${e.message ?? e.code}';
        }
        throw AuthenticationException(errorMessage, e.code);
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthenticationException(
          'Échec de l\'authentification: Aucun utilisateur retourné',
          'NO_USER_RETURNED',
        );
      }

      // 3. Récupérer et synchroniser les données utilisateur (Firestore -> Cache -> State)
      await _fetchAndSyncFirestoreUser(firebaseUser);
      
      AppLogger.info(
        'User successfully logged in: ${firebaseUser.email} (${firebaseUser.uid})',
        name: 'auth.session',
      );

      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email.';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide.';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte utilisateur a été désactivé.';
          break;
        case 'too-many-requests':
          errorMessage = 'Trop de tentatives. Réessayez plus tard.';
          break;
        default:
          errorMessage = 'Erreur d\'authentification: ${e.message}';
      }
      throw AuthenticationException(errorMessage, e.code);
    } catch (e) {
      // Vérifier d'abord si Firebase Auth a réellement fonctionné
      // Si oui, ignorer les erreurs non-critiques (GoogleApiManager, DEVELOPER_ERROR, etc.)
      // MAIS ne pas utiliser currentUser si l'erreur est invalid-credential ou wrong-password
      final errorString = e.toString().toLowerCase();
      final isAuthError =
          errorString.contains('invalid-credential') ||
          errorString.contains('wrong-password') ||
          errorString.contains('user-not-found') ||
          errorString.contains('identifiants invalides');

      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null &&
          firebaseUser.uid.isNotEmpty &&
          !isAuthError) {
        // Vérifier que l'email du currentUser correspond à l'email utilisé pour la connexion
        // Si ce n'est pas le cas, ne pas utiliser currentUser (c'est un utilisateur précédemment connecté)
        if (firebaseUser.email != null &&
            firebaseUser.email!.toLowerCase() != email.toLowerCase()) {
          AppLogger.warning(
            'Current user email (${firebaseUser.email}) does not match login email ($email). Ignoring currentUser.',
            name: 'auth.session',
          );
        } else {
          // Firebase Auth a fonctionné ! Les erreurs GoogleApiManager/DEVELOPER_ERROR sont non-bloquantes
          AppLogger.info(
            'Firebase Auth successful (user: ${firebaseUser.uid}). Error is non-critical (likely GoogleApiManager/DEVELOPER_ERROR): $e',
            name: 'auth.session',
          );

          // Créer l'utilisateur et continuer la connexion
          final appUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? email,
            displayName: 'Administrateur',
            isAdmin: email == _adminEmail,
          );

          // Sauvegarder dans le stockage sécurisé
          await _authStorageService.saveUser(appUser);
          _updateUser(appUser);

          return appUser;
        }
      }

      // Si Firebase Auth n'a pas fonctionné, analyser l'erreur

      // Ignorer les erreurs GoogleApiManager/DEVELOPER_ERROR qui sont non-bloquantes
      // Ces erreurs apparaissent dans les logs mais n'empêchent pas Firebase Auth de fonctionner
      if (errorString.contains('googleapimanager') ||
          errorString.contains('developer_error') ||
          errorString.contains('securityexception') ||
          errorString.contains('unknown calling package')) {
        AppLogger.info(
          'GoogleApiManager/DEVELOPER_ERROR detected (non-critical). Checking if Firebase Auth actually worked...',
          name: 'auth.session',
        );
        // Vérifier à nouveau si un utilisateur existe maintenant
        final userAfterDelay = await Future.delayed(
          const Duration(milliseconds: 500),
          () => _firebaseAuth.currentUser,
        );
        if (userAfterDelay != null &&
            userAfterDelay.email != null &&
            userAfterDelay.email!.toLowerCase() == email.toLowerCase()) {
          // L'utilisateur existe et l'email correspond, la connexion a réussi malgré les erreurs
          final appUser = AppUser(
            id: userAfterDelay.uid,
            email: userAfterDelay.email ?? email,
            displayName: 'Administrateur',
            isAdmin: email == _adminEmail,
          );
          await _authStorageService.saveUser(appUser);
          _updateUser(appUser);
          return appUser;
        }
      }

      // Si c'est une erreur réseau/Firestore, créer l'utilisateur avec valeurs par défaut
      if (errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated') ||
          errorString.contains('timeout')) {
        // Si pas d'utilisateur Firebase, c'est une vraie erreur réseau
        throw NetworkException(
          'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne.',
          'NETWORK_ERROR',
        );
      }

      // Avant de lever une exception, vérifier une dernière fois si Firebase Auth a fonctionné
      // (au cas où l'utilisateur serait disponible maintenant)
      // MAIS seulement si ce n'est pas une erreur d'authentification
      if (!isAuthError) {
        final finalUserCheck = await Future.delayed(
          const Duration(milliseconds: 1000),
          () => _firebaseAuth.currentUser,
        );
        if (finalUserCheck != null &&
            finalUserCheck.uid.isNotEmpty &&
            finalUserCheck.email != null &&
            finalUserCheck.email!.toLowerCase() == email.toLowerCase()) {
          AppLogger.info(
            'Firebase Auth worked after delay (user: ${finalUserCheck.uid}). Error was non-critical: $e',
            name: 'auth.session',
          );
          final appUser = AppUser(
            id: finalUserCheck.uid,
            email: finalUserCheck.email ?? email,
            displayName: 'Administrateur',
            isAdmin: email == _adminEmail,
          );
          await _authStorageService.saveUser(appUser);
          _updateUser(appUser);
          return appUser;
        }
      }

      // Seulement si Firebase Auth n'a vraiment pas fonctionné, vérifier si c'est une erreur d'init
      final isFirebaseInitError =
          errorString.contains('notinitializederror') ||
          errorString.contains('firebaseappnotinitializedexception') ||
          (errorString.contains('not initialized') &&
              errorString.contains('firebaseapp') &&
              !errorString.contains('firestore')); // Exclure les erreurs Firestore

      if (isFirebaseInitError) {
        throw UnknownException(
          'Erreur d\'initialisation : Firebase n\'est pas correctement initialisé. '
          'Veuillez redémarrer l\'application complètement (Stop + Run, pas Hot Reload).',
          'FIREBASE_INIT_ERROR',
        );
      }

      // Pour toutes les autres erreurs, afficher un message générique
      // mais ne pas confondre avec des erreurs d'initialisation Firebase
      throw UnknownException(
        'Erreur de connexion: ${e.toString()}',
        'CONNECTION_ERROR',
      );
    }
  }

  /// Se déconnecter
  Future<void> signOut() async {
    try {
      // Déconnecter de Firebase Auth
      await _firebaseAuth.signOut();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error signing out from Firebase Auth (continuing with local cleanup): ${appException.message}',
        name: 'auth.session',
        error: e,
        stackTrace: stackTrace,
      );
      // Continuer même si la déconnexion Firebase échoue
    }

    // Note: La synchronisation en temps réel sera arrêtée par AuthController.signOut()
    // qui a accès à globalRealtimeSyncService via un import direct.
    // Ici, on nettoie seulement l'état local de AuthSessionService.

    // Nettoyer les données locales (toujours faire, même si Firebase signOut échoue)
    await _authStorageService.clearLocalAuthData();
    _updateUser(null);
    // Ne pas réinitialiser _isInitialized - Firebase Core reste initialisé
    // et le service doit rester prêt pour la prochaine connexion

    AppLogger.info('User signed out successfully', name: 'auth.session');
  }

  /// Recharger l'utilisateur depuis le stockage sécurisé
  Future<void> reloadUser() async {
    _currentUser = await _authStorageService.loadUser();
  }

  /// Force la réinitialisation du service (utile après un clean/rebuild ou en cas de conflit)
  ///
  /// Nettoie toutes les données locales d'authentification et réinitialise l'état.
  /// Cette méthode est utile pour résoudre les conflits entre SecureStorage et Firebase Auth.
  Future<void> forceReset() async {
    AppLogger.info('Force resetting auth session service...', name: 'auth.session');
    await _authStorageService.clearLocalAuthData();
    try {
      await _firebaseAuth.signOut();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error signing out during force reset: ${appException.message}',
        name: 'auth.session',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _updateUser(null);
    _isInitialized = false;
    AppLogger.info('Auth session service reset complete', name: 'auth.session');
  }
}

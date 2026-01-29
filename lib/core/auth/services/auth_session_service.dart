import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, User, UserCredential, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirebaseAuth? firebaseAuth,
    FirestoreUserService? firestoreUserService,
    FirebaseFirestore? firestore,
    AuthStorageService? authStorageService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestoreUserService = firestoreUserService ??
            FirestoreUserService(
              firestore: firestore ?? FirebaseFirestore.instance,
            ),
        _authStorageService =
            authStorageService ?? AuthStorageService();

  final FirebaseAuth _firebaseAuth;
  final FirestoreUserService _firestoreUserService;
  final AuthStorageService _authStorageService;

  AppUser? _currentUser;
  bool _isInitialized = false;

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
        developer.log(
          'Firebase Core not initialized - will work in offline mode',
          name: 'auth.session',
        );
        await _loadUserFromStorage();
        _isInitialized = true;
        return;
      }

      // Migrer les données depuis SharedPreferences si nécessaire
      await _authStorageService.migrateFromSharedPreferences();

      // Vérifier la cohérence entre SecureStorage et Firebase Auth
      // Si SecureStorage dit "logged in" mais Firebase Auth n'a pas d'utilisateur,
      // nettoyer SecureStorage pour éviter les conflits
      final isLoggedInLocal = await _authStorageService.isLoggedIn();
      User? firebaseUser;
      try {
        // Utiliser un timeout court pour éviter d'attendre indéfiniment
        firebaseUser = await Future<User?>.value(
          _firebaseAuth.currentUser,
        ).timeout(const Duration(milliseconds: 1000));
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Firebase Auth not ready or timeout, trying SecureStorage: ${appException.message}',
          name: 'auth.session',
          error: e,
          stackTrace: stackTrace,
        );
        // Si Firebase Auth n'est pas prêt, charger depuis SecureStorage
        await _loadUserFromStorage();
        _isInitialized = true;
        return;
      }

      // Détecter les incohérences : SecureStorage dit "logged in" mais Firebase Auth n'a pas d'utilisateur
      if (isLoggedInLocal && firebaseUser == null) {
        developer.log(
          'Inconsistency detected: SecureStorage says logged in but Firebase Auth has no user. Clearing local auth data.',
          name: 'auth.session',
        );
        // Nettoyer les données d'authentification locales pour éviter les conflits
        await _authStorageService.clearLocalAuthData();
        _currentUser = null;
      }

      if (firebaseUser != null) {
        // Récupérer les données depuis Firestore avec gestion d'erreur améliorée
        try {
          // Attendre un court délai pour s'assurer que Firestore est prêt
          // Cela peut être nécessaire après le déploiement de nouvelles règles
          await Future<void>.delayed(const Duration(milliseconds: 500));

          final userData = await _firestoreUserService
              .getUserById(firebaseUser.uid)
              .timeout(const Duration(seconds: 5));

          if (userData != null) {
            _currentUser = AppUser(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName:
                  userData['firstName'] != null && userData['lastName'] != null
                  ? '${userData['firstName']} ${userData['lastName']}'
                  : userData['username'] as String?,
              isAdmin: userData['isAdmin'] as bool? ?? false,
            );

            // Sauvegarder dans le stockage sécurisé
            await _authStorageService.saveUser(_currentUser!);
          } else {
            // Utilisateur Firebase existe mais pas dans Firestore, charger depuis SecureStorage
            developer.log(
              'User not found in Firestore, loading from SecureStorage',
              name: 'auth.session',
            );
            await _loadUserFromStorage();
          }
        } catch (e, stackTrace) {
          // Détecter si c'est une erreur de réseau/DNS plutôt qu'une erreur de permissions
          final errorString = e.toString().toLowerCase();
          final isNetworkError =
              errorString.contains('unavailable') ||
              errorString.contains('unable to resolve') ||
              errorString.contains('network') ||
              errorString.contains('timeout') ||
              errorString.contains('connection') ||
              errorString.contains('no address associated');

          final appException = ErrorHandler.instance.handleError(e, stackTrace);
          if (isNetworkError) {
            AppLogger.warning(
              'Network error loading user from Firestore (offline mode). Loading from SecureStorage. '
              'This is normal if the device has no internet connection: ${appException.message}',
              name: 'auth.session',
              error: e,
              stackTrace: stackTrace,
            );
          } else {
            AppLogger.warning(
              'Error loading user from Firestore (permissions/rules issue), trying SecureStorage: ${appException.message}',
              name: 'auth.session',
              error: e,
              stackTrace: stackTrace,
            );
          }
          // En cas d'erreur Firestore (réseau, règles, permissions, timeout), charger depuis SecureStorage
          // Ne pas considérer cela comme une erreur fatale - l'utilisateur pourra se reconnecter
          await _loadUserFromStorage();
        }
      } else {
        // Pas d'utilisateur Firebase, charger depuis SecureStorage
        await _loadUserFromStorage();
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
        developer.log(
          'Firebase Core not initialized - this is a critical error',
          name: 'auth.session',
        );
        throw UnknownException(
          'Firebase n\'est pas initialisé. Veuillez redémarrer l\'application.',
          'FIREBASE_NOT_INITIALIZED',
        );
      } else if (isNetworkError) {
        // Erreur réseau - pas un problème d'initialisation, l'app peut fonctionner en offline
        developer.log(
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
      developer.log(
        'Auth session initialized despite Firestore/network errors (will work on login)',
        name: 'auth.session',
      );
      _isInitialized = true;
      return; // Sortir sans throw pour permettre à l'app de continuer
    }

    _isInitialized = true;
  }

  /// Charge l'utilisateur depuis le stockage sécurisé
  Future<void> _loadUserFromStorage() async {
    _currentUser = await _authStorageService.loadUser();
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
            developer.log(
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

      // Vérifier si c'est le premier admin et créer le profil dans Firestore
      // Note: Ces opérations peuvent échouer si Firestore n'est pas encore configuré ou accessible,
      // mais cela n'empêchera pas l'authentification de fonctionner
      bool isFirstAdmin = false;
      try {
        isFirstAdmin = await _firestoreUserService.adminExists().timeout(
          const Duration(seconds: 5),
        );
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error checking if admin exists (Firestore may not be accessible - network issue). Assuming no admin exists for first-time setup: ${appException.message}',
          name: 'auth.session',
          error: e,
          stackTrace: stackTrace,
        );
        // Si la vérification échoue (réseau, permissions, etc.), on assume qu'il n'y a pas d'admin (première connexion)
        // Cela permettra de créer le premier admin même si Firestore n'est pas accessible
        isFirstAdmin = false;
      }

      final shouldBeAdmin = !isFirstAdmin || email == _adminEmail;

      // Créer ou mettre à jour le profil utilisateur dans Firestore
      // Cette opération peut échouer silencieusement si Firestore n'est pas accessible (réseau, permissions)
      // L'authentification continuera quand même et le profil sera créé quand Firestore sera disponible
      // ⚠️ IMPORTANT: Ne pas passer firstName/lastName pour éviter d'écraser les vraies valeurs existantes
      // Si l'utilisateur existe déjà, ses firstName/lastName seront préservés
      // Si c'est un nouvel utilisateur, ils seront vides et pourront être mis à jour via l'admin
      try {
        await _firestoreUserService
            .createOrUpdateUser(
              userId: firebaseUser.uid,
              email: firebaseUser.email ?? email,
              // Ne pas passer firstName/lastName pour éviter d'écraser les valeurs existantes
              username: email.split('@').first,
              isActive: true,
              isAdmin: shouldBeAdmin,
            )
            .timeout(const Duration(seconds: 5));
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error creating user profile in Firestore (network/permissions issue - app will work in offline mode): ${appException.message}',
          name: 'auth.session',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue malgré l'erreur - le profil sera créé quand Firestore sera disponible
        // Firebase Auth a réussi, donc l'utilisateur peut se connecter
      }

      // Récupérer les données utilisateur depuis Firestore
      // Si Firestore n'est pas disponible (réseau, permissions), on utilise les valeurs par défaut
      // Utiliser un timeout court pour ne pas bloquer la connexion
      Map<String, dynamic>? userData;
      try {
        userData = await _firestoreUserService
            .getUserById(firebaseUser.uid)
            .timeout(const Duration(seconds: 2)); // Réduit de 5 à 2 secondes pour accélérer
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error getting user data from Firestore (network/permissions issue - using default values): ${appException.message}',
          name: 'auth.session',
          error: e,
          stackTrace: stackTrace,
        );
        userData = null; // Utilisera les valeurs par défaut
        // Ce n'est pas critique - l'utilisateur peut se connecter avec les valeurs par défaut
        // Les données seront récupérées lors de la synchronisation en arrière-plan
      }

      // Créer l'utilisateur avec les données disponibles
      // Envelopper dans un try-catch pour s'assurer qu'aucune erreur inattendue ne bloque la connexion
      try {
        final appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName:
              userData?['firstName'] != null && userData?['lastName'] != null
              ? '${userData!['firstName']} ${userData['lastName']}'
              : 'Administrateur',
          isAdmin: userData?['isAdmin'] as bool? ?? shouldBeAdmin,
        );

        // Sauvegarder dans le stockage sécurisé
        await _authStorageService.saveUser(appUser);
        _currentUser = appUser;

        developer.log(
          'User successfully logged in: ${appUser.email} (${appUser.id})',
          name: 'auth.session',
        );

        return appUser;
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        // Si la création de l'AppUser échoue, créer avec les valeurs minimales
        AppLogger.warning(
          'Error creating AppUser object, using minimal values: ${appException.message}',
          name: 'auth.session',
          error: e,
          stackTrace: stackTrace,
        );
        final appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: 'Administrateur',
          isAdmin: email == _adminEmail,
        );
        await _authStorageService.saveUser(appUser);
        _currentUser = appUser;
        return appUser;
      }
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
          developer.log(
            'Current user email (${firebaseUser.email}) does not match login email ($email). Ignoring currentUser.',
            name: 'auth.session',
          );
        } else {
          // Firebase Auth a fonctionné ! Les erreurs GoogleApiManager/DEVELOPER_ERROR sont non-bloquantes
          developer.log(
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
          _currentUser = appUser;

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
        developer.log(
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
          _currentUser = appUser;
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
          developer.log(
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
          _currentUser = appUser;
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
    _currentUser = null;
    // Ne pas réinitialiser _isInitialized - Firebase Core reste initialisé
    // et le service doit rester prêt pour la prochaine connexion

    developer.log('User signed out successfully', name: 'auth.session');
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
    developer.log('Force resetting auth session service...', name: 'auth.session');
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
    _currentUser = null;
    _isInitialized = false;
    developer.log('Auth session service reset complete', name: 'auth.session');
  }
}

import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart'
    show
        FirebaseAuth,
        User,
        UserCredential,
        EmailAuthProvider,
        FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../storage/secure_storage_service.dart';
import '../../firebase/firestore_user_service.dart';

/// Modèle utilisateur simple
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'isAdmin': isAdmin,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    isAdmin: json['isAdmin'] as bool? ?? false,
  );
}

/// Service d'authentification avec Firebase Auth et Firestore.
///
/// Utilise Firebase Auth pour l'authentification et Firestore
/// pour stocker les profils utilisateurs.
///
/// Crée automatiquement le premier utilisateur admin dans Firestore
/// lors de la première connexion si aucun admin n'existe.
class AuthService {
  static const String _secureKeyCurrentUserId = 'auth_current_user_id';
  static const String _secureKeyCurrentUserEmail = 'auth_current_user_email';
  static const String _secureKeyCurrentUserDisplayName =
      'auth_current_user_display_name';
  static const String _secureKeyCurrentUserIsAdmin =
      'auth_current_user_is_admin';
  static const String _secureKeyIsLoggedIn = 'auth_is_logged_in';
  static const String _prefsKeyMigrationDone =
      'auth_migration_to_secure_storage_done';

  final FirebaseAuth _firebaseAuth;
  final FirestoreUserService _firestoreUserService;
  final SecureStorageService _secureStorage = SecureStorageService();
  AppUser? _currentUser;
  bool _isInitialized = false;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreUserService? firestoreUserService,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestoreUserService =
           firestoreUserService ??
           FirestoreUserService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  /// Récupère l'email admin depuis les variables d'environnement.
  String get _adminEmail {
    return dotenv.env['ADMIN_EMAIL'] ?? 'admin@elyf.com';
  }

  /// Récupère le mot de passe admin depuis les variables d'environnement.
  // TODO: Utiliser pour validation admin dans le futur
  // ignore: unused_element
  String? get _adminPassword {
    return dotenv.env['ADMIN_PASSWORD'];
  }

  /// Initialiser le service (charger l'utilisateur depuis Firebase Auth et Firestore)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Vérifier d'abord si Firebase Core est initialisé
      if (Firebase.apps.isEmpty) {
        developer.log(
          'Firebase Core not initialized - will work in offline mode',
          name: 'auth',
        );
        await _loadUserFromSecureStorage();
        _isInitialized = true;
        return;
      }

      // Migrer les données depuis SharedPreferences si nécessaire
      await _migrateFromSharedPreferences();

      // Vérifier la cohérence entre SecureStorage et Firebase Auth
      // Si SecureStorage dit "logged in" mais Firebase Auth n'a pas d'utilisateur,
      // nettoyer SecureStorage pour éviter les conflits
      final isLoggedInLocal = await _secureStorage.read(_secureKeyIsLoggedIn);
      User? firebaseUser;
      try {
        // Utiliser un timeout court pour éviter d'attendre indéfiniment
        firebaseUser = await Future<User?>.value(
          _firebaseAuth.currentUser,
        ).timeout(const Duration(milliseconds: 1000));
      } catch (e) {
        developer.log(
          'Firebase Auth not ready or timeout, trying SecureStorage',
          name: 'auth',
          error: e,
        );
        // Si Firebase Auth n'est pas prêt, charger depuis SecureStorage
        await _loadUserFromSecureStorage();
        _isInitialized = true;
        return;
      }

      // Détecter les incohérences : SecureStorage dit "logged in" mais Firebase Auth n'a pas d'utilisateur
      if (isLoggedInLocal == 'true' && firebaseUser == null) {
        developer.log(
          'Inconsistency detected: SecureStorage says logged in but Firebase Auth has no user. Clearing local auth data.',
          name: 'auth',
        );
        // Nettoyer les données d'authentification locales pour éviter les conflits
        await _clearLocalAuthData();
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
            await _saveUser(_currentUser!);
          } else {
            // Utilisateur Firebase existe mais pas dans Firestore, charger depuis SecureStorage
            developer.log(
              'User not found in Firestore, loading from SecureStorage',
              name: 'auth',
            );
            await _loadUserFromSecureStorage();
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

          if (isNetworkError) {
            developer.log(
              'Network error loading user from Firestore (offline mode). Loading from SecureStorage. '
              'This is normal if the device has no internet connection.',
              name: 'auth',
              error: e,
              stackTrace: stackTrace,
            );
          } else {
            developer.log(
              'Error loading user from Firestore (permissions/rules issue), trying SecureStorage',
              name: 'auth',
              error: e,
              stackTrace: stackTrace,
            );
          }
          // En cas d'erreur Firestore (réseau, règles, permissions, timeout), charger depuis SecureStorage
          // Ne pas considérer cela comme une erreur fatale - l'utilisateur pourra se reconnecter
          await _loadUserFromSecureStorage();
        }
      } else {
        // Pas d'utilisateur Firebase, charger depuis SecureStorage
        await _loadUserFromSecureStorage();
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during auth service initialization: ${e.toString()}',
        name: 'auth',
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
          name: 'auth',
        );
        throw Exception(
          'Firebase n\'est pas initialisé. Veuillez redémarrer l\'application.',
        );
      } else if (isNetworkError) {
        // Erreur réseau - pas un problème d'initialisation, l'app peut fonctionner en offline
        developer.log(
          'Network error during auth initialization (offline mode will be used)',
          name: 'auth',
        );
        // Ne pas throw - permettre à l'app de continuer en mode offline
        _isInitialized = true;
        return;
      }

      // Pour les autres erreurs (Firestore permissions, timeout, etc.),
      // marquer comme initialisé pour permettre à l'app de continuer
      // L'utilisateur pourra se connecter et les données seront synchronisées
      developer.log(
        'Auth service initialized despite Firestore/network errors (will work on login)',
        name: 'auth',
      );
      _isInitialized = true;
      return; // Sortir sans throw pour permettre à l'app de continuer
    }

    _isInitialized = true;
  }

  /// Charge l'utilisateur depuis SecureStorage (méthode helper)
  Future<void> _loadUserFromSecureStorage() async {
    try {
      final isLoggedIn = await _secureStorage.read(_secureKeyIsLoggedIn);
      if (isLoggedIn == 'true') {
        final userId = await _secureStorage.read(_secureKeyCurrentUserId);
        final email = await _secureStorage.read(_secureKeyCurrentUserEmail);
        final displayName = await _secureStorage.read(
          _secureKeyCurrentUserDisplayName,
        );
        final isAdminStr = await _secureStorage.read(
          _secureKeyCurrentUserIsAdmin,
        );
        final isAdmin = isAdminStr == 'true';

        if (userId != null && email != null) {
          _currentUser = AppUser(
            id: userId,
            email: email,
            displayName: displayName?.isEmpty ?? true ? null : displayName,
            isAdmin: isAdmin,
          );
        } else {
          // Données incomplètes dans SecureStorage, nettoyer
          developer.log(
            'Incomplete auth data in SecureStorage, clearing',
            name: 'auth',
          );
          await _clearLocalAuthData();
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      developer.log(
        'Error loading user from SecureStorage, clearing local data',
        name: 'auth',
        error: e,
      );
      // En cas d'erreur, nettoyer les données locales pour éviter les conflits
      await _clearLocalAuthData();
      _currentUser = null;
    }
  }

  /// Nettoie les données d'authentification locales (helper pour éviter les conflits)
  Future<void> _clearLocalAuthData() async {
    try {
      await _secureStorage.delete(_secureKeyCurrentUserId);
      await _secureStorage.delete(_secureKeyCurrentUserEmail);
      await _secureStorage.delete(_secureKeyCurrentUserDisplayName);
      await _secureStorage.delete(_secureKeyCurrentUserIsAdmin);
      await _secureStorage.delete(_secureKeyIsLoggedIn);
      developer.log('Local auth data cleared', name: 'auth');
    } catch (e) {
      developer.log('Error clearing local auth data', name: 'auth', error: e);
    }
  }

  /// Migre les données depuis SharedPreferences vers SecureStorage.
  ///
  /// Cette migration est effectuée une seule fois lors de la première
  /// utilisation après la mise à jour.
  ///
  /// Cette méthode ne lance jamais d'exception pour ne pas bloquer l'initialisation.
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationDone = prefs.getBool(_prefsKeyMigrationDone) ?? false;

      if (migrationDone) {
        return; // Migration déjà effectuée
      }

      // Vérifier si des données existent dans SharedPreferences
      final oldIsLoggedIn = prefs.getBool('auth_is_logged_in') ?? false;
      if (!oldIsLoggedIn) {
        // Pas de données à migrer
        await prefs.setBool(_prefsKeyMigrationDone, true);
        return;
      }

      // Migrer les données
      final userId = prefs.getString('auth_current_user_id');
      final email = prefs.getString('auth_current_user_email');
      final displayName = prefs.getString('auth_current_user_displayName');
      final isAdmin = prefs.getBool('auth_current_user_isAdmin') ?? false;

      if (userId != null && email != null) {
        // Sauvegarder dans SecureStorage
        await _secureStorage.write(_secureKeyCurrentUserId, userId);
        await _secureStorage.write(_secureKeyCurrentUserEmail, email);
        await _secureStorage.write(
          _secureKeyCurrentUserDisplayName,
          displayName ?? '',
        );
        await _secureStorage.write(
          _secureKeyCurrentUserIsAdmin,
          isAdmin.toString(),
        );
        await _secureStorage.write(_secureKeyIsLoggedIn, 'true');

        // Supprimer les anciennes données de SharedPreferences
        await prefs.remove('auth_current_user');
        await prefs.remove('auth_current_user_id');
        await prefs.remove('auth_current_user_email');
        await prefs.remove('auth_current_user_displayName');
        await prefs.remove('auth_current_user_isAdmin');
        await prefs.remove('auth_is_logged_in');
      }

      // Marquer la migration comme terminée
      await prefs.setBool(_prefsKeyMigrationDone, true);
    } catch (e, stackTrace) {
      // En cas d'erreur, on continue quand même et on log l'erreur
      // La migration sera réessayée au prochain lancement
      developer.log(
        'Error during migration from SharedPreferences to SecureStorage',
        name: 'auth',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - la migration n'est pas critique
    }
  }

  /// Se connecter avec email et mot de passe via Firebase Auth.
  ///
  /// Crée automatiquement le premier utilisateur admin dans Firestore
  /// lors de la première connexion si aucun admin n'existe.
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
        } catch (e) {
          // Si initialize() échoue (réseau, Firestore, etc.), continuer quand même
          // Firebase Auth peut fonctionner indépendamment
          developer.log(
            'Warning: Auth service initialization failed, but continuing with login: $e',
            name: 'auth',
          );
          // Vérifier si Firebase Auth est disponible quand même
          if (Firebase.apps.isEmpty) {
            throw Exception(
              'Firebase n\'est pas initialisé. Veuillez redémarrer l\'application complètement (Stop + Run).',
            );
          }
          // Vérifier la cohérence : si SecureStorage dit "logged in" mais Firebase Auth n'a pas d'utilisateur,
          // nettoyer pour éviter les conflits lors de la nouvelle connexion
          final isLoggedInLocal = await _secureStorage.read(
            _secureKeyIsLoggedIn,
          );
          final hasFirebaseUser = _firebaseAuth.currentUser != null;
          if (isLoggedInLocal == 'true' && !hasFirebaseUser) {
            developer.log(
              'Inconsistency detected during login: cleaning local auth data',
              name: 'auth',
            );
            await _clearLocalAuthData();
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
        throw Exception(errorMessage);
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception(
          'Échec de l\'authentification: Aucun utilisateur retourné',
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
      } catch (e) {
        developer.log(
          'Error checking if admin exists (Firestore may not be accessible - network issue). Assuming no admin exists for first-time setup: $e',
          name: 'auth',
        );
        // Si la vérification échoue (réseau, permissions, etc.), on assume qu'il n'y a pas d'admin (première connexion)
        // Cela permettra de créer le premier admin même si Firestore n'est pas accessible
        isFirstAdmin = false;
      }

      final shouldBeAdmin = !isFirstAdmin || email == _adminEmail;

      // Créer ou mettre à jour le profil utilisateur dans Firestore
      // Cette opération peut échouer silencieusement si Firestore n'est pas accessible (réseau, permissions)
      // L'authentification continuera quand même et le profil sera créé quand Firestore sera disponible
      try {
        await _firestoreUserService
            .createOrUpdateUser(
              userId: firebaseUser.uid,
              email: firebaseUser.email ?? email,
              firstName: 'Admin',
              lastName: 'System',
              username: email.split('@').first,
              isActive: true,
              isAdmin: shouldBeAdmin,
            )
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        developer.log(
          'Error creating user profile in Firestore (network/permissions issue - app will work in offline mode): $e',
          name: 'auth',
        );
        // Continue malgré l'erreur - le profil sera créé quand Firestore sera disponible
        // Firebase Auth a réussi, donc l'utilisateur peut se connecter
      }

      // Récupérer les données utilisateur depuis Firestore
      // Si Firestore n'est pas disponible (réseau, permissions), on utilise les valeurs par défaut
      Map<String, dynamic>? userData;
      try {
        userData = await _firestoreUserService
            .getUserById(firebaseUser.uid)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        developer.log(
          'Error getting user data from Firestore (network/permissions issue - using default values): $e',
          name: 'auth',
        );
        userData = null; // Utilisera les valeurs par défaut
        // Ce n'est pas critique - l'utilisateur peut se connecter avec les valeurs par défaut
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
        await _saveUser(appUser);
        _currentUser = appUser;

        developer.log(
          'User successfully logged in: ${appUser.email} (${appUser.id})',
          name: 'auth',
        );

        return appUser;
      } catch (e) {
        // Si la création de l'AppUser échoue, créer avec les valeurs minimales
        developer.log(
          'Error creating AppUser object, using minimal values: $e',
          name: 'auth',
        );
        final appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: 'Administrateur',
          isAdmin: email == _adminEmail,
        );
        await _saveUser(appUser);
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
      throw Exception(errorMessage);
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
      if (firebaseUser != null && firebaseUser.uid.isNotEmpty && !isAuthError) {
        // Vérifier que l'email du currentUser correspond à l'email utilisé pour la connexion
        // Si ce n'est pas le cas, ne pas utiliser currentUser (c'est un utilisateur précédemment connecté)
        if (firebaseUser.email != null &&
            firebaseUser.email!.toLowerCase() != email.toLowerCase()) {
          developer.log(
            'Current user email (${firebaseUser.email}) does not match login email ($email). Ignoring currentUser.',
            name: 'auth',
          );
        } else {
          // Firebase Auth a fonctionné ! Les erreurs GoogleApiManager/DEVELOPER_ERROR sont non-bloquantes
          developer.log(
            'Firebase Auth successful (user: ${firebaseUser.uid}). Error is non-critical (likely GoogleApiManager/DEVELOPER_ERROR): $e',
            name: 'auth',
          );

          // Créer l'utilisateur et continuer la connexion
          final appUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? email,
            displayName: 'Administrateur',
            isAdmin: email == _adminEmail,
          );

          // Sauvegarder dans le stockage sécurisé
          await _saveUser(appUser);
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
          name: 'auth',
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
          await _saveUser(appUser);
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
        throw Exception(
          'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne.',
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
            name: 'auth',
          );
          final appUser = AppUser(
            id: finalUserCheck.uid,
            email: finalUserCheck.email ?? email,
            displayName: 'Administrateur',
            isAdmin: email == _adminEmail,
          );
          await _saveUser(appUser);
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
              !errorString.contains(
                'firestore',
              )); // Exclure les erreurs Firestore

      if (isFirebaseInitError) {
        throw Exception(
          'Erreur d\'initialisation : Firebase n\'est pas correctement initialisé. '
          'Veuillez redémarrer l\'application complètement (Stop + Run, pas Hot Reload).',
        );
      }

      // Pour toutes les autres erreurs, afficher un message générique
      // mais ne pas confondre avec des erreurs d'initialisation Firebase
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Crée un compte utilisateur normal dans Firebase Auth.
  ///
  /// Cette méthode crée un utilisateur standard (NON admin).
  /// Pour créer un admin, utiliser createFirstAdmin.
  Future<String> createUserAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Créer le compte dans Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Échec de la création du compte');
      }

      // Note: Le profil utilisateur sera créé dans le module administration
      // via UserController qui gère les détails (firstName, lastName, etc.)
      // On retourne juste l'UID pour créer l'entité User dans le système

      return firebaseUser.uid;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé.';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide.';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible.';
          break;
        default:
          errorMessage = 'Erreur de création: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Erreur lors de la création du compte: ${e.toString()}');
    }
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
    try {
      // Créer le compte dans Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Échec de la création du compte');
      }

      // Créer le profil admin dans Firestore
      await _firestoreUserService.createOrUpdateUser(
        userId: firebaseUser.uid,
        email: email,
        firstName: 'Admin',
        lastName: 'System',
        username: email.split('@').first,
        isActive: true,
        isAdmin: true, // ✅ Uniquement pour le premier admin
      );

      // Récupérer les données depuis Firestore (pour vérification)
      await _firestoreUserService.getUserById(firebaseUser.uid);

      final appUser = AppUser(
        id: firebaseUser.uid,
        email: email,
        displayName: 'Administrateur',
        isAdmin: true, // ✅ Uniquement pour le premier admin
      );

      // Sauvegarder dans le stockage sécurisé
      await _saveUser(appUser);
      _currentUser = appUser;

      return appUser;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé.';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide.';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible.';
          break;
        default:
          errorMessage = 'Erreur de création: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Erreur lors de la création du compte: ${e.toString()}');
    }
  }

  /// Se déconnecter
  Future<void> signOut() async {
    try {
      // Déconnecter de Firebase Auth
      await _firebaseAuth.signOut();
    } catch (e) {
      developer.log(
        'Error signing out from Firebase Auth (continuing with local cleanup): $e',
        name: 'auth',
        error: e,
      );
      // Continuer même si la déconnexion Firebase échoue
    }

    // Note: La synchronisation en temps réel sera arrêtée par AuthController.signOut()
    // qui a accès à globalRealtimeSyncService via un import direct.
    // Ici, on nettoie seulement l'état local de AuthService.

    // Nettoyer les données locales (toujours faire, même si Firebase signOut échoue)
    await _clearLocalAuthData();
    _currentUser = null;
    // Ne pas réinitialiser _isInitialized - Firebase Core reste initialisé
    // et le service doit rester prêt pour la prochaine connexion

    developer.log('User signed out successfully', name: 'auth');
  }

  /// Obtenir l'utilisateur actuel
  AppUser? get currentUser => _currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isAuthenticated => _currentUser != null;

  /// Force la réinitialisation du service (utile après un clean/rebuild ou en cas de conflit)
  ///
  /// Nettoie toutes les données locales d'authentification et réinitialise l'état.
  /// Cette méthode est utile pour résoudre les conflits entre SecureStorage et Firebase Auth.
  Future<void> forceReset() async {
    developer.log('Force resetting auth service...', name: 'auth');
    await _clearLocalAuthData();
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      developer.log('Error signing out during force reset: $e', name: 'auth');
    }
    _currentUser = null;
    _isInitialized = false;
    developer.log('Auth service reset complete', name: 'auth');
  }

  /// Change le mot de passe de l'utilisateur actuel.
  ///
  /// Nécessite une ré-authentification avec le mot de passe actuel pour des raisons de sécurité.
  ///
  /// Paramètres:
  /// - [currentPassword]: Le mot de passe actuel de l'utilisateur
  /// - [newPassword]: Le nouveau mot de passe (minimum 6 caractères)
  ///
  /// Lance une exception si:
  /// - Aucun utilisateur n'est connecté
  /// - Le mot de passe actuel est incorrect
  /// - Le nouveau mot de passe est trop faible
  /// - Une erreur Firebase survient
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    if (firebaseUser.email == null) {
      throw Exception('L\'email de l\'utilisateur n\'est pas disponible');
    }

    try {
      // Étape 1: Ré-authentifier l'utilisateur avec le mot de passe actuel
      // C'est nécessaire pour des raisons de sécurité avant de changer le mot de passe
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      // Étape 2: Mettre à jour le mot de passe
      await firebaseUser.updatePassword(newPassword);

      developer.log(
        'Password changed successfully for user: ${firebaseUser.uid}',
        name: 'auth',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Le mot de passe actuel est incorrect';
          break;
        case 'weak-password':
          errorMessage =
              'Le nouveau mot de passe est trop faible (minimum 6 caractères)';
          break;
        case 'requires-recent-login':
          errorMessage =
              'Cette opération nécessite une reconnexion récente pour des raisons de sécurité';
          break;
        case 'user-mismatch':
          errorMessage =
              'Les identifiants fournis ne correspondent pas à l\'utilisateur connecté';
          break;
        case 'user-not-found':
          errorMessage = 'Utilisateur non trouvé';
          break;
        case 'invalid-credential':
          errorMessage = 'Les identifiants fournis sont invalides';
          break;
        default:
          errorMessage =
              'Erreur lors du changement de mot de passe: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      developer.log('Error changing password', name: 'auth', error: e);
      rethrow;
    }
  }

  /// Sauvegarder l'utilisateur dans le stockage sécurisé
  Future<void> _saveUser(AppUser user) async {
    await _secureStorage.write(_secureKeyCurrentUserId, user.id);
    await _secureStorage.write(_secureKeyCurrentUserEmail, user.email);
    await _secureStorage.write(
      _secureKeyCurrentUserDisplayName,
      user.displayName ?? '',
    );
    await _secureStorage.write(
      _secureKeyCurrentUserIsAdmin,
      user.isAdmin.toString(),
    );
    await _secureStorage.write(_secureKeyIsLoggedIn, 'true');
  }

  /// Recharger l'utilisateur depuis le stockage sécurisé
  Future<void> reloadUser() async {
    final isLoggedIn = await _secureStorage.read(_secureKeyIsLoggedIn);
    if (isLoggedIn == 'true') {
      final userId = await _secureStorage.read(_secureKeyCurrentUserId);
      final email = await _secureStorage.read(_secureKeyCurrentUserEmail);
      final displayName = await _secureStorage.read(
        _secureKeyCurrentUserDisplayName,
      );
      final isAdminStr = await _secureStorage.read(
        _secureKeyCurrentUserIsAdmin,
      );
      final isAdmin = isAdminStr == 'true';

      if (userId != null && email != null) {
        _currentUser = AppUser(
          id: userId,
          email: email,
          displayName: displayName?.isEmpty ?? true ? null : displayName,
          isAdmin: isAdmin,
        );
      } else {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }
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
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(authServiceProvider);

  // Initialiser si nécessaire
  await authService.initialize();

  // Retourner l'utilisateur actuel
  return authService.currentUser;
});

/// Provider pour l'ID de l'utilisateur actuel (compatible avec l'existant)
///
/// Utilise directement AuthService pour éviter les problèmes avec currentUserProvider
/// qui peut être en état de chargement pendant la connexion.
final currentUserIdProvider = Provider<String?>((ref) {
  try {
    // Essayer d'abord avec AuthService directement pour éviter les problèmes
    // de timing avec currentUserProvider qui peut être en chargement
    final authService = ref.read(authServiceProvider);
    if (authService.isAuthenticated && authService.currentUser != null) {
      return authService.currentUser!.id;
    }

    // Si AuthService n'a pas encore l'utilisateur, essayer avec currentUserProvider
    final currentUserAsync = ref.watch(currentUserProvider);
    return currentUserAsync.maybeWhen(
      data: (user) => user?.id,
      orElse: () => null,
    );
  } catch (e) {
    // En cas d'erreur, retourner null (fail-safe)
    return null;
  }
});

/// Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final currentUserAsync = await ref.watch(currentUserProvider.future);
  return currentUserAsync != null;
});

/// Provider pour vérifier si l'utilisateur est admin
final isAdminProvider = Provider<bool>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.value?.isAdmin ?? false;
});

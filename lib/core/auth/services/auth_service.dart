import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/password_hasher.dart';
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
  static const String _secureKeyCurrentUserDisplayName = 'auth_current_user_display_name';
  static const String _secureKeyCurrentUserIsAdmin = 'auth_current_user_is_admin';
  static const String _secureKeyIsLoggedIn = 'auth_is_logged_in';
  static const String _prefsKeyMigrationDone = 'auth_migration_to_secure_storage_done';

  final FirebaseAuth _firebaseAuth;
  final FirestoreUserService _firestoreUserService;
  final SecureStorageService _secureStorage = SecureStorageService();
  AppUser? _currentUser;
  bool _isInitialized = false;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreUserService? firestoreUserService,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestoreUserService = firestoreUserService ??
            FirestoreUserService(
              firestore: firestore ?? FirebaseFirestore.instance,
            );

  /// Récupère l'email admin depuis les variables d'environnement.
  String get _adminEmail {
    return dotenv.env['ADMIN_EMAIL'] ?? 'admin@elyf.com';
  }

  /// Récupère le mot de passe admin depuis les variables d'environnement.
  String? get _adminPassword {
    return dotenv.env['ADMIN_PASSWORD'];
  }

  /// Initialiser le service (charger l'utilisateur depuis Firebase Auth et Firestore)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Migrer les données depuis SharedPreferences si nécessaire
    await _migrateFromSharedPreferences();

    // Vérifier si un utilisateur Firebase est connecté
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      // Récupérer les données depuis Firestore
      final userData = await _firestoreUserService.getUserById(firebaseUser.uid);
      
      if (userData != null) {
        _currentUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: userData['firstName'] != null && userData['lastName'] != null
              ? '${userData['firstName']} ${userData['lastName']}'
              : userData['username'] as String?,
          isAdmin: userData['isAdmin'] as bool? ?? false,
        );
        
        // Sauvegarder dans le stockage sécurisé
        await _saveUser(_currentUser!);
      } else {
        // Utilisateur Firebase existe mais pas dans Firestore, charger depuis SecureStorage
        final isLoggedIn = await _secureStorage.read(_secureKeyIsLoggedIn);
        if (isLoggedIn == 'true') {
          final userId = await _secureStorage.read(_secureKeyCurrentUserId);
          final email = await _secureStorage.read(_secureKeyCurrentUserEmail);
          final displayName = await _secureStorage.read(_secureKeyCurrentUserDisplayName);
          final isAdminStr = await _secureStorage.read(_secureKeyCurrentUserIsAdmin);
          final isAdmin = isAdminStr == 'true';

          if (userId != null && email != null) {
            _currentUser = AppUser(
              id: userId,
              email: email,
              displayName: displayName?.isEmpty ?? true ? null : displayName,
              isAdmin: isAdmin,
            );
          }
        }
      }
    } else {
      // Pas d'utilisateur Firebase, charger depuis SecureStorage
      final isLoggedIn = await _secureStorage.read(_secureKeyIsLoggedIn);
      if (isLoggedIn == 'true') {
        final userId = await _secureStorage.read(_secureKeyCurrentUserId);
        final email = await _secureStorage.read(_secureKeyCurrentUserEmail);
        final displayName = await _secureStorage.read(_secureKeyCurrentUserDisplayName);
        final isAdminStr = await _secureStorage.read(_secureKeyCurrentUserIsAdmin);
        final isAdmin = isAdminStr == 'true';

        if (userId != null && email != null) {
          _currentUser = AppUser(
            id: userId,
            email: email,
            displayName: displayName?.isEmpty ?? true ? null : displayName,
            isAdmin: isAdmin,
          );
        }
      }
    }

    _isInitialized = true;
  }

  /// Migre les données depuis SharedPreferences vers SecureStorage.
  /// 
  /// Cette migration est effectuée une seule fois lors de la première
  /// utilisation après la mise à jour.
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
    } catch (e) {
      // En cas d'erreur, on continue quand même
      // La migration sera réessayée au prochain lancement
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
      if (!_isInitialized) {
        await initialize();
      }

      // Authentifier avec Firebase Auth
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
            errorMessage = 'Aucun compte trouvé avec cet email. Vérifiez que l\'utilisateur existe dans Firebase Console.';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect. Vérifiez votre mot de passe.';
            break;
          case 'invalid-email':
            errorMessage = 'Format d\'email invalide.';
            break;
          case 'user-disabled':
            errorMessage = 'Ce compte a été désactivé. Contactez l\'administrateur.';
            break;
          case 'too-many-requests':
            errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'La connexion par email/mot de passe n\'est pas activée dans Firebase Console.';
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
        throw Exception('Échec de l\'authentification: Aucun utilisateur retourné');
      }

      // Vérifier si c'est le premier admin et créer le profil dans Firestore
      // Note: Ces opérations peuvent échouer si Firestore n'est pas encore configuré,
      // mais cela n'empêchera pas l'authentification de fonctionner
      bool isFirstAdmin = false;
      try {
        isFirstAdmin = await _firestoreUserService.adminExists();
      } catch (e) {
        developer.log(
          'Error checking if admin exists (Firestore may not be configured yet): $e',
          name: 'auth',
        );
        // Si la vérification échoue, on assume qu'il n'y a pas d'admin (première connexion)
        isFirstAdmin = false;
      }
      
      final shouldBeAdmin = !isFirstAdmin || email == _adminEmail;

      // Créer ou mettre à jour le profil utilisateur dans Firestore
      // Cette opération peut échouer silencieusement si Firestore n'est pas configuré
      try {
        await _firestoreUserService.createOrUpdateUser(
          userId: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          firstName: 'Admin',
          lastName: 'System',
          username: email.split('@').first,
          isActive: true,
          isAdmin: shouldBeAdmin,
        );
      } catch (e) {
        developer.log(
          'Error creating user profile in Firestore (may not be configured yet): $e',
          name: 'auth',
        );
        // Continue malgré l'erreur - le profil sera créé quand Firestore sera disponible
      }

      // Récupérer les données utilisateur depuis Firestore
      // Si Firestore n'est pas disponible, on utilise les valeurs par défaut
      Map<String, dynamic>? userData;
      try {
        userData = await _firestoreUserService.getUserById(firebaseUser.uid);
      } catch (e) {
        developer.log(
          'Error getting user data from Firestore (may not be configured yet): $e',
          name: 'auth',
        );
        userData = null; // Utilisera les valeurs par défaut
      }
      
      final appUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: userData?['firstName'] != null && userData?['lastName'] != null
            ? '${userData!['firstName']} ${userData['lastName']}'
            : 'Administrateur',
        isAdmin: userData?['isAdmin'] as bool? ?? shouldBeAdmin,
      );

      // Sauvegarder dans le stockage sécurisé
      await _saveUser(appUser);
      _currentUser = appUser;

      return appUser;
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
    // Déconnecter de Firebase Auth
    await _firebaseAuth.signOut();
    
    // Supprimer les données du stockage sécurisé
    await _secureStorage.delete(_secureKeyCurrentUserId);
    await _secureStorage.delete(_secureKeyCurrentUserEmail);
    await _secureStorage.delete(_secureKeyCurrentUserDisplayName);
    await _secureStorage.delete(_secureKeyCurrentUserIsAdmin);
    await _secureStorage.delete(_secureKeyIsLoggedIn);
    _currentUser = null;
  }

  /// Obtenir l'utilisateur actuel
  AppUser? get currentUser => _currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isAuthenticated => _currentUser != null;

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
      final displayName = await _secureStorage.read(_secureKeyCurrentUserDisplayName);
      final isAdminStr = await _secureStorage.read(_secureKeyCurrentUserIsAdmin);
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
  return FirestoreUserService(
    firestore: FirebaseFirestore.instance,
  );
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
final currentUserIdProvider = Provider<String?>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.value?.id;
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

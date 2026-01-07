import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/password_hasher.dart';
import '../../storage/secure_storage_service.dart';

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

/// Service d'authentification
/// 
/// Utilise flutter_secure_storage pour stocker les données sensibles,
/// des variables d'environnement pour les credentials, et le hashage
/// pour les mots de passe.
/// 
/// Plus tard, ce service sera remplacé par Firebase Auth.
class AuthService {
  static const String _secureKeyCurrentUserId = 'auth_current_user_id';
  static const String _secureKeyCurrentUserEmail = 'auth_current_user_email';
  static const String _secureKeyCurrentUserDisplayName = 'auth_current_user_display_name';
  static const String _secureKeyCurrentUserIsAdmin = 'auth_current_user_is_admin';
  static const String _secureKeyIsLoggedIn = 'auth_is_logged_in';
  static const String _prefsKeyMigrationDone = 'auth_migration_to_secure_storage_done';

  static const String _adminId = 'admin_user_1';

  final SecureStorageService _secureStorage = SecureStorageService();
  AppUser? _currentUser;
  bool _isInitialized = false;

  /// Récupère l'email admin depuis les variables d'environnement.
  String get _adminEmail {
    return dotenv.env['ADMIN_EMAIL'] ?? 'admin@elyf.com';
  }

  /// Récupère le hash du mot de passe admin depuis les variables d'environnement.
  String? get _adminPasswordHash {
    return dotenv.env['ADMIN_PASSWORD_HASH'];
  }

  /// Initialiser le service (charger l'utilisateur depuis le stockage sécurisé)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Migrer les données depuis SharedPreferences si nécessaire
    await _migrateFromSharedPreferences();

    // Charger l'utilisateur depuis le stockage sécurisé
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

  /// Se connecter avec email et mot de passe
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Vérifier l'email
    if (email != _adminEmail) {
      throw Exception('Email ou mot de passe incorrect');
    }

    // Vérifier le hash du mot de passe
    final passwordHash = _adminPasswordHash;
    if (passwordHash == null || passwordHash.isEmpty) {
      throw Exception(
        'Configuration d\'authentification manquante. '
        'Vérifiez que le fichier .env contient ADMIN_PASSWORD_HASH.',
      );
    }

    if (!PasswordHasher.verifyPassword(password, passwordHash)) {
      throw Exception('Email ou mot de passe incorrect');
    }

    // Créer l'utilisateur
    final user = AppUser(
      id: _adminId,
      email: _adminEmail,
      displayName: 'Administrateur',
      isAdmin: true,
    );

    // S'assurer que le service est initialisé avant de sauvegarder
    if (!_isInitialized) {
      await initialize();
    }
    
    // Sauvegarder dans le stockage sécurisé
    await _saveUser(user);
    _currentUser = user;
    return user;
  }

  /// Se déconnecter
  Future<void> signOut() async {
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

/// Provider pour le service d'authentification
/// 
/// Le service est initialisé de manière lazy lors du premier accès.
/// L'initialisation est gérée par le provider currentUserProvider qui attend
/// que le service soit initialisé avant de l'utiliser.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Pour l'instant, utilise un système mock avec un admin par défaut.
/// Plus tard, ce service sera remplacé par Firebase Auth.
class AuthService {
  static const String _prefsKeyCurrentUser = 'auth_current_user';
  static const String _prefsKeyIsLoggedIn = 'auth_is_logged_in';

  // Admin par défaut
  static const String _adminEmail = 'admin@elyf.com';
  static const String _adminPassword = 'admin123';
  static const String _adminId = 'admin_user_1';

  AppUser? _currentUser;
  bool _isInitialized = false;

  /// Initialiser le service (charger l'utilisateur depuis les préférences)
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_prefsKeyIsLoggedIn) ?? false;

    if (isLoggedIn) {
      final userJson = prefs.getString(_prefsKeyCurrentUser);
      if (userJson != null) {
        try {
          // Pour l'instant, on utilise juste l'ID
          final userId = prefs.getString('${_prefsKeyCurrentUser}_id');
          if (userId == _adminId) {
            _currentUser = const AppUser(
              id: _adminId,
              email: _adminEmail,
              displayName: 'Administrateur',
              isAdmin: true,
            );
          }
        } catch (e) {
          // Erreur de parsing, on déconnecte
          await signOut();
        }
      }
    }

    _isInitialized = true;
  }

  /// Se connecter avec email et mot de passe
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Vérifier les credentials de l'admin
    if (email == _adminEmail && password == _adminPassword) {
      final user = const AppUser(
        id: _adminId,
        email: _adminEmail,
        displayName: 'Administrateur',
        isAdmin: true,
      );

      await _saveUser(user);
      _currentUser = user;
      return user;
    }

    throw Exception('Email ou mot de passe incorrect');
  }

  /// Se déconnecter
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyCurrentUser);
    await prefs.remove('${_prefsKeyCurrentUser}_id');
    await prefs.setBool(_prefsKeyIsLoggedIn, false);
    _currentUser = null;
  }

  /// Obtenir l'utilisateur actuel
  AppUser? get currentUser => _currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isAuthenticated => _currentUser != null;

  /// Sauvegarder l'utilisateur dans les préférences
  Future<void> _saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsKeyCurrentUser}_id', user.id);
    await prefs.setString('${_prefsKeyCurrentUser}_email', user.email);
    await prefs.setString('${_prefsKeyCurrentUser}_displayName', user.displayName ?? '');
    await prefs.setBool('${_prefsKeyCurrentUser}_isAdmin', user.isAdmin);
    await prefs.setBool(_prefsKeyIsLoggedIn, true);
  }

  /// Recharger l'utilisateur depuis les préférences
  Future<void> reloadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_prefsKeyIsLoggedIn) ?? false;

    if (isLoggedIn) {
      final userId = prefs.getString('${_prefsKeyCurrentUser}_id');
      if (userId == _adminId) {
        _currentUser = const AppUser(
          id: _adminId,
          email: _adminEmail,
          displayName: 'Administrateur',
          isAdmin: true,
        );
      }
    } else {
      _currentUser = null;
    }
  }
}

/// Provider pour le service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  // Initialiser le service au démarrage
  service.initialize();
  return service;
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


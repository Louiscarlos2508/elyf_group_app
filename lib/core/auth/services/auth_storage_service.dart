import 'package:shared_preferences/shared_preferences.dart';

import '../../errors/error_handler.dart';
import '../../logging/app_logger.dart';
import '../../storage/secure_storage_service.dart';
import '../entities/app_user.dart';

/// Service de gestion du stockage pour l'authentification.
///
/// Gère le stockage sécurisé des données d'authentification,
/// la migration depuis SharedPreferences, et la persistance
/// de l'état de connexion.
class AuthStorageService {
  static const String _secureKeyCurrentUserId = 'auth_current_user_id';
  static const String _secureKeyCurrentUserEmail = 'auth_current_user_email';
  static const String _secureKeyCurrentUserDisplayName =
      'auth_current_user_display_name';
  static const String _secureKeyCurrentUserIsAdmin =
      'auth_current_user_is_admin';
  static const String _secureKeyIsLoggedIn = 'auth_is_logged_in';
  static const String _prefsKeyMigrationDone =
      'auth_migration_to_secure_storage_done';

  final SecureStorageService _secureStorage;
  final SharedPreferences? _prefs;

  AuthStorageService({
    SecureStorageService? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _prefs = prefs;

  /// Charge l'utilisateur depuis SecureStorage.
  ///
  /// Retourne null si aucun utilisateur n'est stocké ou si les données
  /// sont incomplètes.
  Future<AppUser?> loadUser() async {
    try {
      final isLoggedIn = await _secureStorage.read(_secureKeyIsLoggedIn);
      if (isLoggedIn != 'true') {
        return null;
      }

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
        return AppUser(
          id: userId,
          email: email,
          displayName: displayName?.isEmpty ?? true ? null : displayName,
          isAdmin: isAdmin,
        );
      } else {
        // Données incomplètes dans SecureStorage, nettoyer
        AppLogger.info(
          'Incomplete auth data in SecureStorage, clearing',
          name: 'auth.storage',
        );
        await clearLocalAuthData();
        return null;
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error loading user from SecureStorage, clearing local data: ${appException.message}',
        name: 'auth.storage',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, nettoyer les données locales pour éviter les conflits
      await clearLocalAuthData();
      return null;
    }
  }

  /// Sauvegarde l'utilisateur dans le stockage sécurisé.
  Future<void> saveUser(AppUser user) async {
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

  /// Nettoie les données d'authentification locales.
  ///
  /// Utile pour éviter les conflits entre SecureStorage et Firebase Auth.
  Future<void> clearLocalAuthData() async {
    try {
      await _secureStorage.delete(_secureKeyCurrentUserId);
      await _secureStorage.delete(_secureKeyCurrentUserEmail);
      await _secureStorage.delete(_secureKeyCurrentUserDisplayName);
      await _secureStorage.delete(_secureKeyCurrentUserIsAdmin);
      await _secureStorage.delete(_secureKeyIsLoggedIn);
      AppLogger.info('Local auth data cleared', name: 'auth.storage');
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error clearing local auth data: ${appException.message}',
        name: 'auth.storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Vérifie si un utilisateur est connecté selon le stockage local.
  Future<bool> isLoggedIn() async {
    final isLoggedIn = await _secureStorage.read(_secureKeyIsLoggedIn);
    return isLoggedIn == 'true';
  }

  /// Migre les données depuis SharedPreferences vers SecureStorage.
  ///
  /// Cette migration est effectuée une seule fois lors de la première
  /// utilisation après la mise à jour.
  ///
  /// Cette méthode ne lance jamais d'exception pour ne pas bloquer
  /// l'initialisation.
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
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
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error during migration from SharedPreferences to SecureStorage: ${appException.message}',
        name: 'auth.storage',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - la migration n'est pas critique
    }
  }
}

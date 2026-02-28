import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/error_handler.dart';
import '../logging/app_logger.dart';

/// Service pour gérer les utilisateurs dans Firestore.
///
/// Structure Firestore :
/// - Collection: `users`
/// - Document ID: Firebase Auth UID
/// - Champs: id, email, firstName, lastName, username, phone, isActive, isAdmin, createdAt, updatedAt
class FirestoreUserService {
  FirestoreUserService({required this.firestore});

  final FirebaseFirestore firestore;

  /// Collection path pour les utilisateurs
  static const String _usersCollection = 'users';

  /// Crée ou met à jour un utilisateur dans Firestore.
  ///
  /// Si l'utilisateur existe déjà, il sera mis à jour.
  /// Sinon, un nouveau document sera créé.
  /// Si la base de données n'existe pas encore, l'opération est ignorée silencieusement.
  Future<void> createOrUpdateUser({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    bool isActive = true,
    bool isAdmin = false,
    List<String> enterpriseIds = const [],
  }) async {
    try {
      final userDoc = firestore.collection(_usersCollection).doc(userId);
      final userSnapshot = await userDoc.get();

      final userData = {
        'id': userId,
        'email': email,
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'username': username ?? email.split('@').first,
        'phone': phone ?? '',
        'isActive': isActive,
        'isAdmin': isAdmin,
        'enterpriseIds': enterpriseIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!userSnapshot.exists) {
        // Créer un nouvel utilisateur
        userData['createdAt'] = FieldValue.serverTimestamp();
        await userDoc.set(userData);
        AppLogger.info(
          'Created user in Firestore: $userId',
          name: 'firestore.user',
        );
      } else {
        // Mettre à jour l'utilisateur existant
        // ⚠️ IMPORTANT: Ne pas écraser firstName et lastName si l'utilisateur existe déjà
        // et que ces valeurs ne sont pas fournies (pour éviter d'écraser les vraies valeurs)
        final existingData = userSnapshot.data();
        if (existingData != null) {
          // Si firstName/lastName ne sont pas fournis, garder les valeurs existantes
          if (firstName == null || firstName.isEmpty) {
            userData['firstName'] = existingData['firstName'] ?? '';
          }
          if (lastName == null || lastName.isEmpty) {
            userData['lastName'] = existingData['lastName'] ?? '';
          }
          // Si username n'est pas fourni, garder la valeur existante
          if (username == null || username.isEmpty) {
            userData['username'] = existingData['username'] ?? email.split('@').first;
          }
        }
        await userDoc.update(userData);
        AppLogger.info(
          'Updated user in Firestore: $userId',
          name: 'firestore.user',
        );
      }
    } on FirebaseException catch (e, stackTrace) {
      // Gérer les erreurs Firebase (permissions, règles, réseau, etc.)
      final errorCode = e.code.toLowerCase();
      final isNetworkError =
          errorCode == 'unavailable' ||
          errorCode.contains('network') ||
          e.message?.toLowerCase().contains('unable to resolve') == true ||
          e.message?.toLowerCase().contains('no address') == true;

      if (isNetworkError) {
        AppLogger.error(
          'Network error creating/updating user in Firestore (code: ${e.code}). User profile will be created when network is available: $userId',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      } else {
        AppLogger.error(
          'Firebase error creating/updating user in Firestore (code: ${e.code}): ${e.message}. User profile will be created when Firestore is available: $userId',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      }
      // Ne pas rethrow - permet à l'authentification de continuer
      return;
    } catch (e, stackTrace) {
      // Détecter les erreurs réseau dans les exceptions génériques
      final errorString = e.toString().toLowerCase();
      final isNetworkError =
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('timeout') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated');

      if (isNetworkError) {
        AppLogger.error(
          'Network error creating/updating user in Firestore. User profile will be created when network is available: $userId',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      } else if (errorString.contains('not_found') ||
          errorString.contains('does not exist') ||
          errorString.contains('database')) {
        AppLogger.info(
          'Firestore database not found yet - user profile will be created when database is available: $userId',
          name: 'firestore.user',
        );
      } else {
        AppLogger.error(
          'Error creating/updating user in Firestore. User profile will be created when Firestore is available: $userId',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      }
      // Ne pas rethrow - permet à l'authentification de continuer
      // L'utilisateur pourra se connecter et le profil sera créé quand Firestore sera disponible
    }
  }

  /// Récupère un utilisateur par son ID.
  ///
  /// Retourne null si l'utilisateur n'existe pas ou en cas d'erreur.
  /// Ne lance pas d'exception pour permettre à l'authentification de continuer
  /// même si Firestore a des problèmes (permissions, règles, réseau).
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final userDoc = firestore.collection(_usersCollection).doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        AppLogger.info(
          'User not found in Firestore: $userId',
          name: 'firestore.user',
        );
        return null;
      }

      return userSnapshot.data();
    } on FirebaseException catch (e, stackTrace) {
      // Gérer spécifiquement les erreurs Firebase (permissions, règles, réseau, etc.)
      final errorCode = e.code.toLowerCase();
      final isNetworkError =
          errorCode == 'unavailable' ||
          errorCode.contains('network') ||
          e.message?.toLowerCase().contains('unable to resolve') == true ||
          e.message?.toLowerCase().contains('no address') == true;

      if (isNetworkError) {
        AppLogger.error(
          'Network error getting user from Firestore (code: ${e.code}). App will work in offline mode.',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      } else {
        AppLogger.error(
          'Firebase error getting user from Firestore (code: ${e.code}): ${e.message}',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      }
      // Ne pas rethrow - retourner null pour permettre à l'app de continuer en mode offline
      return null;
    } catch (e, stackTrace) {
      // Détecter les erreurs réseau dans les exceptions génériques
      final errorString = e.toString().toLowerCase();
      final isNetworkError =
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('timeout') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated');

      if (isNetworkError) {
        AppLogger.error(
          'Network error getting user from Firestore. App will work in offline mode: $e',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      } else {
        AppLogger.error(
          'Unexpected error getting user from Firestore: $e',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }

  /// Vérifie si un utilisateur existe dans Firestore.
  Future<bool> userExists(String userId) async {
    try {
      final userDoc = firestore.collection(_usersCollection).doc(userId);
      final userSnapshot = await userDoc.get();
      return userSnapshot.exists;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error checking if user exists: ${appException.message}',
        name: 'firestore.user',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Vérifie si un utilisateur admin existe dans Firestore.
  ///
  /// Retourne true si au moins un utilisateur avec isAdmin=true existe.
  /// Retourne false si la base de données n'existe pas encore ou en cas d'erreur.
  /// Ne lance jamais d'exception pour permettre à l'authentification de continuer.
  Future<bool> adminExists() async {
    try {
      final querySnapshot = await firestore
          .collection(_usersCollection)
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      return querySnapshot.docs.isNotEmpty;
    } on FirebaseException catch (e, stackTrace) {
      // Gérer les erreurs Firebase (permissions, règles, réseau, etc.)
      final errorCode = e.code.toLowerCase();
      final isNetworkError =
          errorCode == 'unavailable' ||
          errorCode.contains('network') ||
          e.message?.toLowerCase().contains('unable to resolve') == true ||
          e.message?.toLowerCase().contains('no address') == true;

      if (isNetworkError) {
        AppLogger.error(
          'Network error checking if admin exists (code: ${e.code}). Assuming no admin exists for first-time setup.',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      } else {
        AppLogger.error(
          'Firebase error checking if admin exists (code: ${e.code}). Assuming no admin exists: ${e.message}',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      }
      // Retourner false pour permettre la création du premier admin
      return false;
    } catch (e, stackTrace) {
      // Détecter les erreurs réseau dans les exceptions génériques
      final errorString = e.toString().toLowerCase();
      final isNetworkError =
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('timeout') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated');

      if (isNetworkError) {
        AppLogger.error(
          'Network error checking if admin exists. Assuming no admin exists for first-time setup: $e',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      } else if (errorString.contains('not_found') ||
          errorString.contains('does not exist') ||
          errorString.contains('database')) {
        AppLogger.info(
          'Firestore database not found yet - assuming no admin exists',
          name: 'firestore.user',
        );
      } else {
        AppLogger.error(
          'Error checking if admin exists. Assuming no admin exists: $e',
          name: 'firestore.user',
          error: e,
          stackTrace: stackTrace,
        );
      }
      // Toujours retourner false pour permettre la création du premier admin
      // Même en cas d'erreur, on assume qu'il n'y a pas d'admin
      return false;
    }
  }

  /// Met à jour le statut admin d'un utilisateur.
  Future<void> updateAdminStatus(String userId, bool isAdmin) async {
    try {
      await firestore.collection(_usersCollection).doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info(
        'Updated admin status for user: $userId -> isAdmin: $isAdmin',
        name: 'firestore.user',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error updating admin status: ${appException.message}',
        name: 'firestore.user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

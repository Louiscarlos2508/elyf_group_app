import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, User, EmailAuthProvider, FirebaseAuthException;

import '../../errors/app_exceptions.dart';
import '../../errors/error_handler.dart';
import '../../logging/app_logger.dart';
import '../../firebase/firestore_user_service.dart';
import '../entities/app_user.dart';
import 'auth_storage_service.dart';

/// Service de gestion des utilisateurs pour l'authentification.
///
/// Gère la création de comptes utilisateurs, la création du premier admin,
/// et le changement de mot de passe.
class AuthUserService {
  AuthUserService({
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

  /// Crée un compte utilisateur normal dans Firebase Auth.
  ///
  /// Cette méthode crée un utilisateur standard (NON admin).
  /// Pour créer un admin, utiliser createFirstAdmin.
  ///
  /// Retourne l'UID de l'utilisateur créé.
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
        throw AuthenticationException(
          'Échec de la création du compte',
          'ACCOUNT_CREATION_FAILED',
        );
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
      throw AuthenticationException(errorMessage, e.code);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de la création du compte: ${appException.message}',
        name: 'auth.user',
        error: e,
        stackTrace: stackTrace,
      );
      throw UnknownException(
        'Erreur lors de la création du compte: ${appException.message}',
        'ACCOUNT_CREATION_ERROR',
      );
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
        throw AuthenticationException(
          'Échec de la création du compte',
          'ACCOUNT_CREATION_FAILED',
        );
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
      await _authStorageService.saveUser(appUser);

      developer.log(
        'First admin created successfully: ${appUser.email} (${appUser.id})',
        name: 'auth.user',
      );

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
      throw AuthenticationException(errorMessage, e.code);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de la création du compte: ${appException.message}',
        name: 'auth.user',
        error: e,
        stackTrace: stackTrace,
      );
      throw UnknownException(
        'Erreur lors de la création du compte: ${appException.message}',
        'ACCOUNT_CREATION_ERROR',
      );
    }
  }

  /// Change le mot de passe de l'utilisateur actuel.
  ///
  /// Nécessite une ré-authentification avec le mot de passe actuel
  /// pour des raisons de sécurité.
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
      throw AuthenticationException(
        'Aucun utilisateur connecté',
        'NO_USER_CONNECTED',
      );
    }

    if (firebaseUser.email == null) {
      throw ValidationException(
        'L\'email de l\'utilisateur n\'est pas disponible',
        'EMAIL_NOT_AVAILABLE',
      );
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
        name: 'auth.user',
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
      throw AuthenticationException(errorMessage, e.code);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error changing password: ${appException.message}',
        name: 'auth.user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

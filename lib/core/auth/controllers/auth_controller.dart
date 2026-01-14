import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../../firebase/firestore_user_service.dart';
import '../../../app/bootstrap.dart' show globalRealtimeSyncService;

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
  ///
  /// Attend également que la synchronisation initiale des données
  /// (rôles, permissions, entreprises) soit terminée avant de retourner.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Ne pas appeler initialize() ici - signInWithEmailAndPassword() le gère
      // de manière plus robuste avec gestion d'erreur appropriée
      // Cela évite de bloquer le login si initialize() échoue pour des raisons non-critiques

      // Connexion avec Firebase Auth
      // Le service crée automatiquement le profil dans Firestore
      // et le premier admin si nécessaire
      // signInWithEmailAndPassword() initialise le service si nécessaire
      final user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // S'assurer que la synchronisation est démarrée et attendre qu'elle soit terminée
      if (globalRealtimeSyncService != null) {
        // Si la synchronisation n'est pas en cours, la redémarrer
        if (!globalRealtimeSyncService!.isListening) {
          developer.log(
            'Realtime sync not running, starting it...',
            name: 'auth.controller',
          );
          try {
            await globalRealtimeSyncService!.startRealtimeSync();
            developer.log(
              'Realtime sync started after login',
              name: 'auth.controller',
            );
          } catch (e) {
            developer.log(
              'Warning: Failed to start realtime sync after login (will continue anyway): $e',
              name: 'auth.controller',
            );
            // Continuer même si le démarrage échoue - les données peuvent déjà être en cache
          }
        }

        // Attendre que la synchronisation initiale soit terminée pour que
        // les données de rôles/permissions soient disponibles
        developer.log(
          'Waiting for initial sync to complete after login...',
          name: 'auth.controller',
        );
        try {
          await globalRealtimeSyncService!.waitForInitialPull(
            timeout: const Duration(seconds: 15),
          );
          developer.log(
            'Initial sync completed after login',
            name: 'auth.controller',
          );
        } catch (e) {
          developer.log(
            'Warning: Initial sync timeout or error after login (continuing anyway): $e',
            name: 'auth.controller',
          );
          // Continuer même si le timeout est atteint - les données se chargeront progressivement
        }
      }

      return user;
    } catch (e) {
      // Améliorer les messages d'erreur selon le type d'erreur
      final errorString = e.toString().toLowerCase();

      // Erreur réseau (pas d'initialisation Firebase)
      if (errorString.contains('unavailable') ||
          errorString.contains('unable to resolve') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('no address associated')) {
        throw Exception(
          'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne. '
          'Assurez-vous que votre appareil a accès à Internet pour synchroniser les données.',
        );
      }

      // Vraie erreur d'initialisation Firebase Core
      if (errorString.contains('notinitializederror') ||
          (errorString.contains('not initialized') &&
              errorString.contains('firebaseapp'))) {
        throw Exception(
          'Erreur d\'initialisation : Firebase n\'est pas correctement initialisé. '
          'Veuillez redémarrer l\'application.',
        );
      }
      rethrow;
    }
  }

  /// Créer le premier utilisateur admin.
  ///
  /// Cette méthode est utilisée lors de la première installation
  /// pour créer le compte admin par défaut.
  Future<AppUser> createFirstAdmin({
    required String email,
    required String password,
  }) async {
    return await authService.createFirstAdmin(email: email, password: password);
  }

  /// Se déconnecter.
  ///
  /// Nettoie l'état d'authentification de l'utilisateur.
  ///
  /// Note: La synchronisation en temps réel des données administratives
  /// (roles, entreprises, enterprise_module_users) continue de fonctionner
  /// car ces données sont partagées entre tous les utilisateurs.
  Future<void> signOut() async {
    // Note: On ne stop PAS la synchronisation en temps réel car les données
    // (roles, entreprises, enterprise_module_users) sont globales et partagées.
    // La synchronisation reste active pour le prochain utilisateur qui se connectera.

    // Déconnecter de l'auth service
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

  /// Change le mot de passe de l'utilisateur actuel.
  ///
  /// Nécessite une ré-authentification avec le mot de passe actuel.
  ///
  /// Paramètres:
  /// - [currentPassword]: Le mot de passe actuel de l'utilisateur
  /// - [newPassword]: Le nouveau mot de passe (minimum 6 caractères)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Met à jour le profil de l'utilisateur actuel.
  ///
  /// Met à jour les informations personnelles de l'utilisateur dans Firestore.
  ///
  /// Paramètres:
  /// - [userId]: L'ID de l'utilisateur à mettre à jour
  /// - [firstName]: Le prénom de l'utilisateur
  /// - [lastName]: Le nom de famille de l'utilisateur
  /// - [username]: Le nom d'utilisateur
  /// - [email]: L'email de l'utilisateur
  /// - [phone]: Le numéro de téléphone (optionnel)
  /// - [isActive]: Si l'utilisateur est actif (par défaut: true)
  /// - [isAdmin]: Si l'utilisateur est admin (par défaut: false)
  Future<void> updateProfile({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    bool isActive = true,
    bool isAdmin = false,
  }) async {
    await firestoreUserService.createOrUpdateUser(
      userId: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      username: username,
      phone: phone,
      isActive: isActive,
      isAdmin: isAdmin,
    );
  }
}

/// Provider pour le controller d'authentification.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    authService: ref.watch(authServiceProvider),
    firestoreUserService: ref.watch(firestoreUserServiceProvider),
  );
});

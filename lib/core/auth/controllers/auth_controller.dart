import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/app_exceptions.dart';
import '../../errors/error_handler.dart';
import '../../logging/app_logger.dart';
import '../entities/entities.dart';
import '../../tenant/tenant_provider.dart';
import '../services/auth_service.dart';
import '../../firebase/firestore_user_service.dart';
import '../../../app/bootstrap.dart'
    show globalRealtimeSyncService, globalModuleRealtimeSyncService;
import '../../../core/offline/sync_paths.dart';
import '../../../core/offline/drift_service.dart';
import '../../../core/offline/module_data_sync_service.dart';
import '../../../features/administration/application/controllers/admin_controller.dart';
import '../../../features/administration/application/providers.dart'
    show adminControllerProvider;

/// Controller pour gérer l'authentification.
///
/// Encapsule la logique métier d'authentification et expose
/// des méthodes simples pour l'UI.
class AuthController {
  AuthController({
    required this.authService,
    required this.firestoreUserService,
    required Ref ref,
    AdminController? adminController,
    FirebaseFirestore? firestore,
  })  : _ref = ref,
        _adminController = adminController,
        _firestore = firestore;

  final AuthService authService;
  final FirestoreUserService firestoreUserService;
  final Ref _ref;
  final AdminController? _adminController;
  final FirebaseFirestore? _firestore;

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

      // Démarrer la synchronisation en arrière-plan (ne bloque pas la connexion)
      // Les données se chargeront progressivement après la connexion
      if (globalRealtimeSyncService != null) {
        // Si la synchronisation n'est pas en cours, la démarrer en arrière-plan
        if (!globalRealtimeSyncService!.isListening) {
          developer.log(
            'Starting realtime sync in background after login...',
            name: 'auth.controller',
          );
          // Démarrer la sync en arrière-plan sans attendre
          globalRealtimeSyncService!.startRealtimeSync(userId: user.id).catchError((error) {
            developer.log(
              'Error starting realtime sync in background',
              name: 'auth.controller',
              error: error,
            );
            // Continuer même si le démarrage échoue - les données peuvent déjà être en cache
          });
        } else {
          developer.log(
            'Realtime sync already running, skipping start',
            name: 'auth.controller',
          );
        }
        
        // Ne PAS attendre le pull initial - permettre à l'utilisateur de se connecter immédiatement
        // Les données se chargeront progressivement en arrière-plan
        // Si les données sont déjà en cache (Drift), elles seront disponibles immédiatement
        developer.log(
          'Login completed - data will sync in background',
          name: 'auth.controller',
        );
      }

      // Synchroniser les modules métier auxquels l'utilisateur a accès
      // (en arrière-plan, ne bloque pas la connexion)
      _syncUserModulesInBackground(user.id).catchError((error) {
        developer.log(
          'Error syncing user modules after login (non-blocking): $error',
          name: 'auth.controller',
          error: error,
        );
      });

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
        throw NetworkException(
          'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne. '
          'Assurez-vous que votre appareil a accès à Internet pour synchroniser les données.',
          'NETWORK_ERROR',
        );
      }

      // Vraie erreur d'initialisation Firebase Core
      if (errorString.contains('notinitializederror') ||
          (errorString.contains('not initialized') &&
              errorString.contains('firebaseapp'))) {
        throw UnknownException(
          'Erreur d\'initialisation : Firebase n\'est pas correctement initialisé. '
          'Veuillez redémarrer l\'application.',
          'FIREBASE_INIT_ERROR',
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
  ///
  /// La synchronisation en temps réel des modules métier est arrêtée car
  /// elle est spécifique à l'utilisateur connecté.
  Future<void> signOut() async {
    // Note: On ne stop PAS la synchronisation en temps réel des données
    // administratives car elles sont globales et partagées.
    // La synchronisation reste active pour le prochain utilisateur qui se connectera.

    // Arrêter la synchronisation en temps réel des modules métier
    // (spécifique à l'utilisateur connecté)
    if (globalModuleRealtimeSyncService != null) {
      try {
        await globalModuleRealtimeSyncService!.stopAllRealtimeSync();
        developer.log(
          'Stopped all module realtime syncs on logout',
          name: 'auth.controller',
        );
      } catch (e) {
        // ... (existing error handling)
      }
    }

    // Arrêter aussi la sync admin pour qu'elle puisse redémarrer pour le nouvel utilisateur
    if (globalRealtimeSyncService != null) {
      try {
        await globalRealtimeSyncService!.stopRealtimeSync();
        developer.log(
          'Stopped admin realtime sync on logout',
          name: 'auth.controller',
        );
      } catch (e) {
        developer.log('Error stopping admin realtime sync on logout: $e');
      }
    }

    // Nettoyer l'entreprise active
    try {
      await _ref.read(activeEnterpriseIdProvider.notifier).clearActiveEnterprise();
    } catch (e) {
      developer.log('Error clearing active enterprise on logout: $e');
    }

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

  /// Synchronise en arrière-plan tous les modules auxquels l'utilisateur a accès.
  ///
  /// Cette méthode est appelée après la connexion pour s'assurer que les données
  /// des modules métier sont synchronisées depuis Firestore vers le stockage local.
  ///
  /// Ne bloque pas la connexion - s'exécute en arrière-plan.
  Future<void> _syncUserModulesInBackground(String userId) async {
    // Ne pas synchroniser si AdminController ou Firestore ne sont pas disponibles
    final adminController = _adminController;
    final firestore = _firestore;
    if (adminController == null || firestore == null) {
      developer.log(
        'AdminController or Firestore not available, skipping module sync',
        name: 'auth.controller',
      );
      return;
    }

    try {
      developer.log(
        'Starting background sync of user modules for user $userId',
        name: 'auth.controller',
      );

      // Récupérer tous les accès EnterpriseModuleUser de l'utilisateur
      final userAccesses = await adminController.getUserEnterpriseModuleUsers(
        userId,
      );

      // Filtrer uniquement les accès actifs
      final activeAccesses = userAccesses.where((access) => access.isActive).toList();

      if (activeAccesses.isEmpty) {
        developer.log(
          'No active module accesses found for user $userId',
          name: 'auth.controller',
        );
        return;
      }

      developer.log(
        'Found ${activeAccesses.length} active module accesses for user $userId',
        name: 'auth.controller',
      );

      // Grouper par entreprise et module pour éviter les doublons
      final syncTasks = <String, Set<String>>{};
      for (final access in activeAccesses) {
        syncTasks.putIfAbsent(access.enterpriseId, () => <String>{}).add(
              access.moduleId,
            );
      }

      // Synchroniser chaque module pour chaque entreprise
      final syncService = ModuleDataSyncService(
        firestore: firestore,
        driftService: DriftService.instance,
        collectionPaths: collectionPaths,
      );

      // Démarrer la synchronisation en temps réel pour tous les modules
      final globalModuleSync = globalModuleRealtimeSyncService;

      int syncedCount = 0;
      int realtimeSyncCount = 0;
      for (final entry in syncTasks.entries) {
        final enterpriseId = entry.key;
        final moduleIds = entry.value;

        for (final moduleId in moduleIds) {
          try {
            developer.log(
              'Syncing module $moduleId for enterprise $enterpriseId',
              name: 'auth.controller',
            );
            // 1. Pull initial des données
            await syncService.syncModuleData(
              enterpriseId: enterpriseId,
              moduleId: moduleId,
            );
            syncedCount++;

            // 2. Démarrer la synchronisation en temps réel pour ce module
            if (globalModuleSync != null) {
              try {
                await globalModuleSync.startRealtimeSync(
                  enterpriseId: enterpriseId,
                  moduleId: moduleId,
                );
                realtimeSyncCount++;
                developer.log(
                  'Realtime sync started for module $moduleId in enterprise $enterpriseId',
                  name: 'auth.controller',
                );
              } catch (e, stackTrace) {
                final appException = ErrorHandler.instance.handleError(e, stackTrace);
                AppLogger.warning(
                  'Error starting realtime sync for module $moduleId: ${appException.message}',
                  name: 'auth.controller',
                  error: e,
                  stackTrace: stackTrace,
                );
                // Continuer même si la sync en temps réel échoue
              }
            }

            developer.log(
              'Successfully synced module $moduleId for enterprise $enterpriseId',
              name: 'auth.controller',
            );
          } catch (e, stackTrace) {
            final appException = ErrorHandler.instance.handleError(e, stackTrace);
            AppLogger.warning(
              'Error syncing module $moduleId for enterprise $enterpriseId: ${appException.message}',
              name: 'auth.controller',
              error: e,
              stackTrace: stackTrace,
            );
            // Continuer avec les autres modules même si un échoue
          }
        }
      }

      developer.log(
        'Background module sync completed: $syncedCount modules synced, $realtimeSyncCount realtime syncs started',
        name: 'auth.controller',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error during background module sync: ${appException.message}',
        name: 'auth.controller',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas rethrow - cette synchronisation ne doit pas bloquer la connexion
    }
  }
}

/// Provider pour le controller d'authentification.
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    authService: ref.watch(authServiceProvider),
    firestoreUserService: ref.watch(firestoreUserServiceProvider),
    adminController: ref.watch(adminControllerProvider),
    firestore: FirebaseFirestore.instance,
    ref: ref,
  );
});

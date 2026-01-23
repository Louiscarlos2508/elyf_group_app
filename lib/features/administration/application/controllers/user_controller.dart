import 'dart:developer' as developer;

import '../../domain/entities/user.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/audit/audit_service.dart';
import '../../domain/services/validation/permission_validator_service.dart';
import '../../data/services/firebase_auth_integration_service.dart';
import '../../data/services/firestore_sync_service.dart';

/// Controller pour gérer les utilisateurs.
///
/// Intègre Firebase Auth, Firestore sync, audit trail et validation des permissions.
class UserController {
  UserController(
    this._repository, {
    this.auditService,
    this.permissionValidator,
    this.firebaseAuthIntegration,
    this.firestoreSync,
  });

  final UserRepository _repository;
  final AuditService? auditService;
  final PermissionValidatorService? permissionValidator;
  final FirebaseAuthIntegrationService? firebaseAuthIntegration;
  final FirestoreSyncService? firestoreSync;

  /// Récupère tous les utilisateurs.
  ///
  /// Lit UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée.
  /// La synchronisation avec Firestore est gérée par le RealtimeSyncService.
  Future<List<User>> getAllUsers() async {
    try {
      // Lire UNIQUEMENT depuis la base locale (Drift) pour éviter la lecture simultanée
      // La synchronisation avec Firestore est gérée par le RealtimeSyncService
      final localUsers = await _repository.getAllUsers();

      // Dédupliquer les utilisateurs par ID pour éviter les duplications
      // (peut arriver si la synchronisation crée des doublons dans Drift)
      final uniqueUsers = <String, User>{};
      for (final user in localUsers) {
        // Garder le premier utilisateur trouvé avec chaque ID
        if (!uniqueUsers.containsKey(user.id)) {
          uniqueUsers[user.id] = user;
        }
      }

      return uniqueUsers.values.toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting all users from local database: $e',
        name: 'user.controller',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Récupère un utilisateur par son ID.
  Future<User?> getUserById(String userId) async {
    return await _repository.getUserById(userId);
  }

  /// Récupère un utilisateur par son nom d'utilisateur.
  Future<User?> getUserByUsername(String username) async {
    return await _repository.getUserByUsername(username);
  }

  /// Recherche des utilisateurs par nom, prénom ou username.
  Future<List<User>> searchUsers(String query) async {
    return await _repository.searchUsers(query);
  }

  /// Crée un nouvel utilisateur.
  ///
  /// Optionally creates Firebase Auth user if email and password are provided.
  /// Logs audit trail and syncs to Firestore.
  Future<User> createUser(
    User user, {
    String? password,
    String? currentUserId,
  }) async {
    // Create Firebase Auth user if email and password are provided
    if (user.email != null &&
        password != null &&
        password.isNotEmpty &&
        firebaseAuthIntegration != null) {
      try {
        final firebaseUid = await firebaseAuthIntegration!.createFirebaseUser(
          email: user.email!,
          password: password,
          displayName: '${user.firstName} ${user.lastName}',
        );
        // Update user ID to Firebase UID
        user = user.copyWith(id: firebaseUid);
      } catch (e) {
        // If Firebase Auth creation fails, continue with local user
        // but log the error
      }
    }

    // Create user in repository (local Drift database)
    User createdUser;
    try {
      createdUser = await _repository.createUser(user);
    } catch (e) {
      // Si la sauvegarde locale échoue, on continue quand même
      // L'utilisateur existe dans Firestore et sera récupéré lors de la prochaine sync
      developer.log(
        'Error saving user to local database (user created in Firestore, will be synced later): $e',
        name: 'user.controller',
      );
      // Créer un objet utilisateur temporaire avec les données fournies
      // pour permettre à l'opération de continuer
      createdUser = user.copyWith(
        createdAt: user.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Sync to Firestore (cela peut avoir déjà été fait via Firebase Auth)
    try {
      await firestoreSync?.syncUserToFirestore(createdUser);
    } catch (e) {
      developer.log(
        'Error syncing user to Firestore (may already exist): $e',
        name: 'user.controller',
      );
      // Ne pas bloquer - l'utilisateur peut déjà exister dans Firestore
    }

    // Récupérer le nom de l'utilisateur qui fait l'action pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null) {
      try {
        final actingUser = await _repository.getUserById(currentUserId);
        userDisplayName = actingUser?.fullName;
      } catch (e) {
        developer.log(
          'Error fetching user for audit log: $e',
          name: 'user.controller',
        );
      }
    }

    // Log audit trail
    try {
      auditService?.logAction(
        action: AuditAction.create,
        entityType: 'user',
        entityId: createdUser.id,
        userId: currentUserId ?? 'system',
        description: 'User created: ${createdUser.fullName}',
        newValue: createdUser.toMap(),
        userDisplayName: userDisplayName,
      );
    } catch (e) {
      developer.log('Error logging audit trail: $e', name: 'user.controller');
      // Ne pas bloquer si l'audit échoue
    }

    return createdUser;
  }

  /// Met à jour un utilisateur existant.
  ///
  /// Logs audit trail and syncs to Firestore.
  Future<User> updateUser(
    User user, {
    String? currentUserId,
    User? oldUser,
  }) async {
    // Get old user if not provided
    final oldUserData = oldUser ?? await _repository.getUserById(user.id);

    // Update user in repository
    // Note: save() dans OfflineRepository queue automatiquement la sync via SyncManager
    // Pas besoin d'appel direct à syncUserToFirestore ici
    final updatedUser = await _repository.updateUser(user);
    
    developer.log(
      'User updated in repository: ${updatedUser.id}, name: ${updatedUser.fullName}',
      name: 'user.controller',
    );

    // Update Firebase Auth profile if email changed
    if (user.email != null &&
        oldUserData?.email != user.email &&
        firebaseAuthIntegration != null) {
      try {
        await firebaseAuthIntegration!.updateFirebaseUserProfile(
          userId: user.id,
          displayName: '${user.firstName} ${user.lastName}',
        );
        developer.log(
          'Firebase Auth profile updated for user: ${user.id}',
          name: 'user.controller',
        );
      } catch (e, stackTrace) {
        developer.log(
          'Error updating Firebase Auth profile: $e',
          name: 'user.controller',
          error: e,
          stackTrace: stackTrace,
        );
        // Log error but continue - the user is already saved locally
      }
    }

    // Note: La synchronisation vers Firestore est gérée automatiquement par SyncManager
    // via la queue de sync dans OfflineRepository.save(). Pas besoin d'appel direct ici.
    // L'appel direct à syncUserToFirestore peut échouer silencieusement et créer des incohérences.

    // Récupérer le nom de l'utilisateur qui fait l'action pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null) {
      try {
        final actingUser = await _repository.getUserById(currentUserId);
        userDisplayName = actingUser?.fullName;
      } catch (e) {
        developer.log(
          'Error fetching user for audit log: $e',
          name: 'user.controller',
        );
      }
    }

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.update,
      entityType: 'user',
      entityId: updatedUser.id,
      userId: currentUserId ?? 'system',
      description: 'User updated: ${updatedUser.fullName}',
      oldValue: oldUserData?.toMap(),
      newValue: updatedUser.toMap(),
      userDisplayName: userDisplayName,
    );

    return updatedUser;
  }

  /// Supprime un utilisateur.
  ///
  /// Optionally deletes Firebase Auth user and logs audit trail.
  Future<void> deleteUser(
    String userId, {
    String? currentUserId,
    User? userData,
  }) async {
    // Get user data if not provided
    final user = userData ?? await _repository.getUserById(userId);
    if (user == null) return;

    // Delete Firebase Auth user if exists
    // Note: Firebase Auth deletion should happen immediately as it's authentication-related
    if (firebaseAuthIntegration != null) {
      try {
        await firebaseAuthIntegration!.deleteFirebaseUser(userId);
      } catch (e) {
        developer.log(
          'Error deleting Firebase Auth user: $e',
          name: 'user.controller',
          error: e,
        );
        // Log error but continue with local deletion
        // The user will be removed from local storage and sync queue
      }
    }

    // Delete from repository (this will queue sync to Firestore automatically)
    // Note: La synchronisation vers Firestore est gérée automatiquement par le repository
    // via la queue de sync (SyncManager). Pas besoin d'appel manuel ici.
    await _repository.deleteUser(userId);

    // Récupérer le nom de l'utilisateur qui fait l'action pour l'audit trail
    String? userDisplayName;
    if (currentUserId != null) {
      try {
        final actingUser = await _repository.getUserById(currentUserId);
        userDisplayName = actingUser?.fullName;
      } catch (e) {
        developer.log(
          'Error fetching user for audit log: $e',
          name: 'user.controller',
        );
      }
    }

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.delete,
      entityType: 'user',
      entityId: userId,
      userId: currentUserId ?? 'system',
      description: 'User deleted: ${user.fullName}',
      oldValue: user.toMap(),
      userDisplayName: userDisplayName,
    );
  }

  /// Active ou désactive un utilisateur.
  ///
  /// Logs audit trail and syncs to Firestore.
  Future<void> toggleUserStatus(
    String userId,
    bool isActive, {
    String? currentUserId,
  }) async {
    final oldUser = await _repository.getUserById(userId);
    if (oldUser == null) return;

    await _repository.toggleUserStatus(userId, isActive);

    final updatedUser = await _repository.getUserById(userId);
    if (updatedUser != null) {
      // Sync to Firestore
      firestoreSync?.syncUserToFirestore(updatedUser, isUpdate: true);

      // Récupérer le nom de l'utilisateur qui fait l'action pour l'audit trail
      String? userDisplayName;
      if (currentUserId != null) {
        try {
          final actingUser = await _repository.getUserById(currentUserId);
          userDisplayName = actingUser?.fullName;
        } catch (e) {
          developer.log(
            'Error fetching user for audit log: $e',
            name: 'user.controller',
          );
        }
      }

      // Log audit trail
      auditService?.logAction(
        action: isActive ? AuditAction.activate : AuditAction.deactivate,
        entityType: 'user',
        entityId: userId,
        userId: currentUserId ?? 'system',
        description:
            'User ${isActive ? 'activated' : 'deactivated'}: ${updatedUser.fullName}',
        oldValue: oldUser.toMap(),
        newValue: updatedUser.toMap(),
        userDisplayName: userDisplayName,
      );
    }
  }
}

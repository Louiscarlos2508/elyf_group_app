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
  /// Essaie d'abord depuis la base locale (Drift), puis depuis Firestore
  /// si la base locale est vide ou en cas d'erreur.
  Future<List<User>> getAllUsers() async {
    try {
      final localUsers = await _repository.getAllUsers();
      
      // Si la base locale contient des utilisateurs, les retourner
      if (localUsers.isNotEmpty) {
        return localUsers;
      }
      
      // Si la base locale est vide, essayer de récupérer depuis Firestore
      // et sauvegarder localement pour la prochaine fois
      if (firestoreSync != null) {
        try {
          final firestoreUsers = await firestoreSync!.pullUsersFromFirestore();
          
          // Sauvegarder chaque utilisateur dans la base locale SANS déclencher de sync
          // (ces utilisateurs viennent déjà de Firestore, pas besoin de les re-synchroniser)
          for (final user in firestoreUsers) {
            try {
              // Utiliser directement saveToLocal pour éviter de mettre dans la queue de sync
              // Les utilisateurs viennent déjà de Firestore, donc pas besoin de les re-sync
              await (_repository as dynamic).saveToLocal(user);
            } catch (e) {
              // Ignorer les erreurs de sauvegarde locale individuelle
              // (peut-être que l'utilisateur existe déjà)
              developer.log(
                'Error saving user from Firestore to local database: ${user.id}',
                name: 'user.controller',
              );
            }
          }
          
          // Retourner les utilisateurs depuis Firestore
          if (firestoreUsers.isNotEmpty) {
            developer.log(
              'Loaded ${firestoreUsers.length} users from Firestore (local database was empty)',
              name: 'user.controller',
            );
            return firestoreUsers;
          }
        } catch (e) {
          developer.log(
            'Error fetching users from Firestore (will use empty local list): $e',
            name: 'user.controller',
          );
          // Continuer avec la liste locale (vide)
        }
      }
      
      return localUsers;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting all users from local database, trying Firestore: $e',
        name: 'user.controller',
        error: e,
        stackTrace: stackTrace,
      );
      
      // En cas d'erreur locale, essayer Firestore
      if (firestoreSync != null) {
        try {
          final firestoreUsers = await firestoreSync!.pullUsersFromFirestore();
          developer.log(
            'Loaded ${firestoreUsers.length} users from Firestore (local database error)',
            name: 'user.controller',
          );
          return firestoreUsers;
        } catch (e) {
          developer.log(
            'Error fetching users from Firestore: $e',
            name: 'user.controller',
          );
        }
      }
      
      // Si tout échoue, retourner une liste vide
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
      developer.log(
        'Error logging audit trail: $e',
        name: 'user.controller',
      );
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
    final updatedUser = await _repository.updateUser(user);

    // Update Firebase Auth profile if email changed
    if (user.email != null &&
        oldUserData?.email != user.email &&
        firebaseAuthIntegration != null) {
      try {
        await firebaseAuthIntegration!.updateFirebaseUserProfile(
          userId: user.id,
          displayName: '${user.firstName} ${user.lastName}',
        );
      } catch (e) {
        // Log error but continue
      }
    }

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
    if (firebaseAuthIntegration != null) {
      try {
        await firebaseAuthIntegration!.deleteFirebaseUser(userId);
      } catch (e) {
        // Log error but continue with local deletion
      }
    }

    // Delete from Firestore
    firestoreSync?.deleteFromFirestore(
      collection: 'users',
      documentId: userId,
    );

    // Delete from repository
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
        description: 'User ${isActive ? 'activated' : 'deactivated'}: ${updatedUser.fullName}',
        oldValue: oldUser.toMap(),
        newValue: updatedUser.toMap(),
        userDisplayName: userDisplayName,
      );
    }
  }
}


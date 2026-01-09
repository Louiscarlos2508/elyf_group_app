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
  Future<List<User>> getAllUsers() async {
    return await _repository.getAllUsers();
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

    // Create user in repository
    final createdUser = await _repository.createUser(user);

    // Sync to Firestore
    firestoreSync?.syncUserToFirestore(createdUser);

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.create,
      entityType: 'user',
      entityId: createdUser.id,
      userId: currentUserId ?? 'system',
      description: 'User created: ${createdUser.fullName}',
      newValue: createdUser.toMap(),
    );

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

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.update,
      entityType: 'user',
      entityId: updatedUser.id,
      userId: currentUserId ?? 'system',
      description: 'User updated: ${updatedUser.fullName}',
      oldValue: oldUserData?.toMap(),
      newValue: updatedUser.toMap(),
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

    // Log audit trail
    auditService?.logAction(
      action: AuditAction.delete,
      entityType: 'user',
      entityId: userId,
      userId: currentUserId ?? 'system',
      description: 'User deleted: ${user.fullName}',
      oldValue: user.toMap(),
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

      // Log audit trail
      auditService?.logAction(
        action: isActive ? AuditAction.activate : AuditAction.deactivate,
        entityType: 'user',
        entityId: userId,
        userId: currentUserId ?? 'system',
        description: 'User ${isActive ? 'activated' : 'deactivated'}: ${updatedUser.fullName}',
        oldValue: oldUser.toMap(),
        newValue: updatedUser.toMap(),
      );
    }
  }
}


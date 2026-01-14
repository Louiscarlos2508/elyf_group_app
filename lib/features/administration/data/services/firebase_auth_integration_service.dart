import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/services/auth_service.dart';

/// Service for integrating user creation with Firebase Auth.
///
/// Creates Firebase Auth users when creating admin users.
class FirebaseAuthIntegrationService {
  FirebaseAuthIntegrationService({required this.authService});

  final AuthService authService;

  /// Create a Firebase Auth user with email and password.
  ///
  /// Returns the Firebase Auth UID to use as the user ID.
  Future<String> createFirebaseUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Create user in Firebase Auth using AuthService
      // ✅ Utilise createUserAccount pour créer un utilisateur NORMAL (pas admin)
      final firebaseUid = await authService.createUserAccount(
        email: email,
        password: password,
        displayName: displayName,
      );

      developer.log(
        'Firebase Auth user created (normal user, not admin): $firebaseUid',
        name: 'admin.firebase.auth',
      );

      // Update display name if provided
      if (displayName != null && firebaseUid.isNotEmpty) {
        try {
          await updateFirebaseUserProfile(
            userId: firebaseUid,
            displayName: displayName,
          );
        } catch (e) {
          // Log but don't fail - display name is optional
          developer.log(
            'Failed to set display name: $e',
            name: 'admin.firebase.auth',
          );
        }
      }

      return firebaseUid;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating Firebase Auth user',
        name: 'admin.firebase.auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update Firebase Auth user profile.
  Future<void> updateFirebaseUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('User not authenticated or ID mismatch');
      }

      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();

      developer.log(
        'Firebase Auth profile updated for user: $userId',
        name: 'admin.firebase.auth',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating Firebase Auth profile',
        name: 'admin.firebase.auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete Firebase Auth user.
  Future<void> deleteFirebaseUser(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('User not authenticated or ID mismatch');
      }

      await user.delete();

      developer.log(
        'Firebase Auth user deleted: $userId',
        name: 'admin.firebase.auth',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting Firebase Auth user',
        name: 'admin.firebase.auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Reset password for a user.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      developer.log(
        'Password reset email sent to: $email',
        name: 'admin.firebase.auth',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error sending password reset email',
        name: 'admin.firebase.auth',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

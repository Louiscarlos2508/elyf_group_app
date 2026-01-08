import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour gérer les utilisateurs dans Firestore.
/// 
/// Structure Firestore :
/// - Collection: `users`
/// - Document ID: Firebase Auth UID
/// - Champs: id, email, firstName, lastName, username, phone, isActive, isAdmin, createdAt, updatedAt
class FirestoreUserService {
  FirestoreUserService({
    required this.firestore,
  });

  final FirebaseFirestore firestore;

  /// Collection path pour les utilisateurs
  static const String _usersCollection = 'users';

  /// Crée ou met à jour un utilisateur dans Firestore.
  /// 
  /// Si l'utilisateur existe déjà, il sera mis à jour.
  /// Sinon, un nouveau document sera créé.
  Future<void> createOrUpdateUser({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    bool isActive = true,
    bool isAdmin = false,
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!userSnapshot.exists) {
        // Créer un nouvel utilisateur
        userData['createdAt'] = FieldValue.serverTimestamp();
        await userDoc.set(userData);
        developer.log(
          'Created user in Firestore: $userId',
          name: 'firestore.user',
        );
      } else {
        // Mettre à jour l'utilisateur existant
        await userDoc.update(userData);
        developer.log(
          'Updated user in Firestore: $userId',
          name: 'firestore.user',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error creating/updating user in Firestore',
        name: 'firestore.user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère un utilisateur par son ID.
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final userDoc = firestore.collection(_usersCollection).doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        return null;
      }

      return userSnapshot.data();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user from Firestore',
        name: 'firestore.user',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Vérifie si un utilisateur existe dans Firestore.
  Future<bool> userExists(String userId) async {
    try {
      final userDoc = firestore.collection(_usersCollection).doc(userId);
      final userSnapshot = await userDoc.get();
      return userSnapshot.exists;
    } catch (e) {
      developer.log(
        'Error checking if user exists',
        name: 'firestore.user',
        error: e,
      );
      return false;
    }
  }

  /// Vérifie si un utilisateur admin existe dans Firestore.
  /// 
  /// Retourne true si au moins un utilisateur avec isAdmin=true existe.
  Future<bool> adminExists() async {
    try {
      final querySnapshot = await firestore
          .collection(_usersCollection)
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking if admin exists',
        name: 'firestore.user',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Met à jour le statut admin d'un utilisateur.
  Future<void> updateAdminStatus(String userId, bool isAdmin) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log(
        'Updated admin status for user: $userId -> isAdmin: $isAdmin',
        name: 'firestore.user',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating admin status',
        name: 'firestore.user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}


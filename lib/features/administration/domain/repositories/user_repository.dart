import '../entities/user.dart';

/// Repository pour la gestion des utilisateurs.
abstract class UserRepository {
  /// Récupère tous les utilisateurs.
  Future<List<User>> getAllUsers();

  /// Récupère un utilisateur par son ID.
  Future<User?> getUserById(String userId);

  /// Récupère un utilisateur par son nom d'utilisateur.
  Future<User?> getUserByUsername(String username);

  /// Recherche des utilisateurs par nom, prénom ou username.
  Future<List<User>> searchUsers(String query);

  /// Crée un nouvel utilisateur.
  Future<User> createUser(User user);

  /// Met à jour un utilisateur existant.
  Future<User> updateUser(User user);

  /// Supprime un utilisateur.
  Future<void> deleteUser(String userId);

  /// Active ou désactive un utilisateur.
  Future<void> toggleUserStatus(String userId, bool isActive);
}


import '../entities/user.dart';

/// Repository pour la gestion des utilisateurs.
abstract class UserRepository {
  /// Récupère tous les utilisateurs.
  Future<List<User>> getAllUsers();

  /// Récupère les utilisateurs avec pagination (LIMIT/OFFSET au niveau Drift).
  ///
  /// Returns a paginated list of users and the total count.
  Future<({List<User> users, int totalCount})> getUsersPaginated({
    int page = 0,
    int limit = 50,
  });

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

  /// Vérifie et crée le premier utilisateur admin par défaut si aucun utilisateur n'existe.
  ///
  /// Cette méthode est appelée lors de la première connexion pour s'assurer
  /// qu'un utilisateur admin existe dans le système.
  ///
  /// Retourne l'utilisateur admin (créé ou existant).
  Future<User> ensureDefaultAdminExists({
    required String adminId,
    required String adminEmail,
    String? adminPasswordHash,
  });
}

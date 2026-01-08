import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Controller pour gérer les utilisateurs.
class UserController {
  UserController(this._repository);

  final UserRepository _repository;

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
  Future<User> createUser(User user) async {
    return await _repository.createUser(user);
  }

  /// Met à jour un utilisateur existant.
  Future<User> updateUser(User user) async {
    return await _repository.updateUser(user);
  }

  /// Supprime un utilisateur.
  Future<void> deleteUser(String userId) async {
    return await _repository.deleteUser(userId);
  }

  /// Active ou désactive un utilisateur.
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    return await _repository.toggleUserStatus(userId, isActive);
  }
}


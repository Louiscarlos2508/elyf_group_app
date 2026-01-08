import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Implémentation mock du UserRepository pour le développement.
class MockUserRepository implements UserRepository {
  final List<User> _users = [];

  MockUserRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();
    // Le premier admin sera créé automatiquement via ensureDefaultAdminExists
    // On garde les autres utilisateurs mock pour les tests
    _users.addAll([
      User(
        id: 'user-2',
        firstName: 'Jean',
        lastName: 'Dupont',
        username: 'jdupont',
        email: 'jean.dupont@elyf.com',
        phone: '+226 70 11 11 11',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now,
      ),
      User(
        id: 'user-3',
        firstName: 'Marie',
        lastName: 'Martin',
        username: 'mmartin',
        email: 'marie.martin@elyf.com',
        phone: '+226 70 22 22 22',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      User(
        id: 'user-4',
        firstName: 'Pierre',
        lastName: 'Kone',
        username: 'pkone',
        email: 'pierre.kone@elyf.com',
        isActive: false,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
    ]);
  }

  @override
  Future<List<User>> getAllUsers() async {
    return List.from(_users);
  }

  @override
  Future<User?> getUserById(String userId) async {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    try {
      return _users.firstWhere((u) => u.username == username);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) return getAllUsers();

    final lowerQuery = query.toLowerCase();
    return _users.where((user) {
      return user.firstName.toLowerCase().contains(lowerQuery) ||
          user.lastName.toLowerCase().contains(lowerQuery) ||
          user.username.toLowerCase().contains(lowerQuery) ||
          (user.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<User> createUser(User user) async {
    // Vérifier que le username n'existe pas déjà
    final existing = await getUserByUsername(user.username);
    if (existing != null) {
      throw Exception('Un utilisateur avec ce nom d\'utilisateur existe déjà');
    }

    final newUser = user.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<User> updateUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      throw Exception('Utilisateur non trouvé');
    }

    // Vérifier que le username n'est pas déjà utilisé par un autre utilisateur
    final existing = await getUserByUsername(user.username);
    if (existing != null && existing.id != user.id) {
      throw Exception('Un utilisateur avec ce nom d\'utilisateur existe déjà');
    }

    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    _users[index] = updatedUser;
    return updatedUser;
  }

  @override
  Future<void> deleteUser(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Utilisateur non trouvé');
    }
    _users.removeAt(index);
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    final user = await getUserById(userId);
    if (user == null) {
      throw Exception('Utilisateur non trouvé');
    }
    await updateUser(user.copyWith(isActive: isActive));
  }

  @override
  Future<User> ensureDefaultAdminExists({
    required String adminId,
    required String adminEmail,
    String? adminPasswordHash,
  }) async {
    // Vérifier si un utilisateur admin existe déjà
    final existingAdmin = await getUserById(adminId);
    if (existingAdmin != null) {
      return existingAdmin;
    }

    // Vérifier si un utilisateur avec cet email existe déjà
    try {
      final existingByEmail = _users.firstWhere(
        (u) => u.email == adminEmail,
      );
      // Un utilisateur avec cet email existe déjà
      // On retourne l'existant
      return existingByEmail;
    } catch (e) {
      // Aucun utilisateur avec cet email, on continue pour créer le premier admin
    }

    // Créer le premier admin par défaut
    final now = DateTime.now();
    final defaultAdmin = User(
      id: adminId,
      firstName: 'Admin',
      lastName: 'System',
      username: 'admin',
      email: adminEmail,
      phone: '+226 70 00 00 00',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    _users.insert(0, defaultAdmin);
    return defaultAdmin;
  }
}


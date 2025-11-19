import '../entities/user.dart';

/// Authentication and user management repository.
abstract class AuthRepository {
  Future<User?> login(String username, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<void> updateProfile(String userId, String firstName, String lastName);
  Future<void> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  );
}

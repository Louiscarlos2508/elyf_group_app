/// Represents a system user with role-based access.
class User {
  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.passwordHash,
  });

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? passwordHash;

  String get fullName => '$firstName $lastName';

  bool get isManager => role == UserRole.manager;
  bool get isEmployee => role == UserRole.employee;
}

enum UserRole { manager, employee }

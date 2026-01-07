/// Represents user profile information.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.role,
    this.email,
    this.phone,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String role;
  final String? email;
  final String? phone;

  String get fullName => '$firstName $lastName';

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      id: 'user-1',
      firstName: 'Responsable',
      lastName: 'Admin',
      username: 'responsable',
      role: 'Responsable',
    );
  }
}


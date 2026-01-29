/// Modèle utilisateur simple pour l'authentification.
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'isAdmin': isAdmin,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        isAdmin: json['isAdmin'] as bool? ?? false,
      );
}

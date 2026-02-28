/// Modèle utilisateur simple pour l'authentification.
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;
  final List<String> enterpriseIds;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.isAdmin = false,
    this.enterpriseIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'isAdmin': isAdmin,
        'enterpriseIds': enterpriseIds,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        isAdmin: json['isAdmin'] as bool? ?? false,
        enterpriseIds: (json['enterpriseIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

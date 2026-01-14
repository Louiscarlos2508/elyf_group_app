/// Represents a user in a specific module with their role and permissions.
class ModuleUser {
  const ModuleUser({
    required this.userId,
    required this.moduleId,
    required this.roleId,
    this.customPermissions = const {},
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// ID of the user (from auth system)
  final String userId;

  /// ID of the module (e.g., 'eau_minerale', 'gaz', etc.)
  final String moduleId;

  /// ID of the role assigned to this user
  final String roleId;

  /// Additional custom permissions (beyond role permissions)
  final Set<String> customPermissions;

  /// Whether the user is active in this module
  final bool isActive;

  /// When the user was added to this module
  final DateTime? createdAt;

  /// When the user's permissions were last updated
  final DateTime? updatedAt;

  /// Create a copy with modified fields
  ModuleUser copyWith({
    String? userId,
    String? moduleId,
    String? roleId,
    Set<String>? customPermissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuleUser(
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      roleId: roleId ?? this.roleId,
      customPermissions: customPermissions ?? this.customPermissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

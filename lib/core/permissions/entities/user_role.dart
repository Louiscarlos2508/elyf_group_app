/// Represents a user role with associated permissions.
class UserRole {
  const UserRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    this.isSystemRole = false,
  });

  /// Unique identifier for the role
  final String id;

  /// Human-readable name
  final String name;

  /// Description of the role
  final String description;

  /// Set of permission IDs this role has
  final Set<String> permissions;

  /// Whether this is a system role that cannot be deleted
  final bool isSystemRole;

  /// Check if role has a specific permission
  bool hasPermission(String permissionId) {
    return permissions.contains(permissionId);
  }

  /// Check if role has any of the specified permissions
  bool hasAnyPermission(Set<String> permissionIds) {
    return permissionIds.any((id) => permissions.contains(id));
  }

  /// Check if role has all specified permissions
  bool hasAllPermissions(Set<String> permissionIds) {
    return permissionIds.every((id) => permissions.contains(id));
  }

  /// Create a copy with modified fields
  UserRole copyWith({
    String? id,
    String? name,
    String? description,
    Set<String>? permissions,
    bool? isSystemRole,
  }) {
    return UserRole(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isSystemRole: isSystemRole ?? this.isSystemRole,
    );
  }
}

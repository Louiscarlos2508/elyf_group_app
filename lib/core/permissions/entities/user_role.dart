import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

/// Represents a user role with associated permissions.
class UserRole {
  const UserRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.moduleId,
    this.isSystemRole = false,
    this.allowedEnterpriseTypes = const {},
  });

  /// Unique identifier for the role
  final String id;

  /// Human-readable name
  final String name;

  /// Description of the role
  final String description;

  /// Set of permission IDs this role has
  final Set<String> permissions;

  /// ID du module auquel ce rôle appartient (ex: "gaz", "boutique")
  final String moduleId;

  /// Whether this is a system role that cannot be deleted
  final bool isSystemRole;

  /// Types d'entreprises autorisés pour ce rôle
  /// Si vide, le rôle peut être assigné à n'importe quel type d'entreprise
  /// Exemples:
  /// - {EnterpriseType.gasCompany} → Rôle niveau Société uniquement
  /// - {EnterpriseType.gasPointOfSale} → Rôle niveau POS uniquement
  /// - {} → Tous niveaux (flexible)
  final Set<EnterpriseType> allowedEnterpriseTypes;

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

  /// Vérifie si ce rôle peut être assigné à un type d'entreprise donné
  bool canBeAssignedTo(EnterpriseType enterpriseType) {
    // Si aucune restriction, le rôle peut être assigné partout
    if (allowedEnterpriseTypes.isEmpty) return true;

    // Sinon, vérifier si le type est dans la liste autorisée
    return allowedEnterpriseTypes.contains(enterpriseType);
  }

  /// Obtient une description lisible des types d'entreprises autorisés
  String getAllowedTypesLabel() {
    if (allowedEnterpriseTypes.isEmpty) {
      return 'Tous niveaux';
    }
    return allowedEnterpriseTypes.map((t) => t.label).join(', ');
  }

  /// Create a copy with modified fields
  UserRole copyWith({
    String? id,
    String? name,
    String? description,
    Set<String>? permissions,
    String? moduleId,
    bool? isSystemRole,
    Set<EnterpriseType>? allowedEnterpriseTypes,
  }) {
    return UserRole(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      moduleId: moduleId ?? this.moduleId,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      allowedEnterpriseTypes:
          allowedEnterpriseTypes ?? this.allowedEnterpriseTypes,
    );
  }

  /// Create from Map (Firestore)
  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      permissions:
          (map['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      moduleId: map['moduleId'] as String? ?? 'general',
      isSystemRole: map['isSystemRole'] as bool? ?? false,
      allowedEnterpriseTypes:
          (map['allowedEnterpriseTypes'] as List<dynamic>?)
              ?.map((e) => EnterpriseType.fromId(e as String))
              .toSet() ??
          const {},
    );
  }

  /// Convert to Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions.toList(),
      'moduleId': moduleId,
      'isSystemRole': isSystemRole,
      'allowedEnterpriseTypes': allowedEnterpriseTypes
          .map((e) => e.id)
          .toList(),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Représente un utilisateur dans une entreprise spécifique avec un module et un rôle.
///
/// Cette entité remplace ModuleUser pour supporter le multi-tenant (entreprise).
///
/// Exemple:
/// - userId: "user123" (Firebase Auth UID)
/// - enterpriseId: "eau_sachet_1" (Entreprise spécifique)
/// - moduleId: "eau_minerale" (Module dans cette entreprise)
/// - roleId: "gestionnaire_eau_minerale" (Rôle assigné)
class EnterpriseModuleUser {
  const EnterpriseModuleUser({
    required this.userId,
    required this.enterpriseId,
    required this.moduleId,
    required this.roleIds,
    this.customPermissions = const {},
    this.isActive = true,
    this.includesChildren = false,
    this.parentEnterpriseId,
    this.createdAt,
    this.updatedAt,
  });

  /// ID de l'utilisateur (Firebase Auth UID)
  final String userId;

  /// ID de l'entreprise (ex: "eau_sachet_1", "gaz_1")
  final String enterpriseId;

  /// ID du module (ex: "eau_minerale", "gaz", "orange_money")
  final String moduleId;

  /// IDs des rôles assignés (ex: ["vendeur", "gestionnaire_stock"])
  final List<String> roleIds;

  /// Rôle principal (pour compatibilité)
  String get roleId => roleIds.isNotEmpty ? roleIds.first : '';

  /// Permissions personnalisées supplémentaires (au-delà du rôle)
  final Set<String> customPermissions;

  /// Indique si l'utilisateur est actif dans cette entreprise/module
  final bool isActive;

  /// Indique si l'accès inclut automatiquement les sous-entreprises
  /// Si true, l'utilisateur a accès à cette entreprise ET à tous ses enfants
  final bool includesChildren;

  /// ID de l'entreprise parente (pour validation des permissions hiérarchiques)
  /// Crucial si enterpriseId est un sous-tenant (Agence/POS)
  final String? parentEnterpriseId;

  /// Date de création de l'accès
  final DateTime? createdAt;

  /// Date de dernière mise à jour
  final DateTime? updatedAt;

  /// Crée une copie avec des champs modifiés
  EnterpriseModuleUser copyWith({
    String? userId,
    String? enterpriseId,
    String? moduleId,
    List<String>? roleIds,
    Set<String>? customPermissions,
    bool? isActive,
    bool? includesChildren,
    String? parentEnterpriseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnterpriseModuleUser(
      userId: userId ?? this.userId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      roleIds: roleIds ?? this.roleIds,
      customPermissions: customPermissions ?? this.customPermissions,
      isActive: isActive ?? this.isActive,
      includesChildren: includesChildren ?? this.includesChildren,
      parentEnterpriseId: parentEnterpriseId ?? this.parentEnterpriseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'enterpriseId': enterpriseId,
      'moduleId': moduleId,
      'roleIds': roleIds,
      'customPermissions': customPermissions.toList(),
      'isActive': isActive,
      'includesChildren': includesChildren,
      'parentEnterpriseId': parentEnterpriseId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Crée depuis un Map Firestore
  factory EnterpriseModuleUser.fromMap(Map<String, dynamic> map) {
    // Robust parsing of roleIds with fallback to roleId
    final dynamic roleIdsData = map['roleIds'];
    final List<String> roleIds = [];
    
    if (roleIdsData is List) {
      roleIds.addAll(roleIdsData.map((e) => e.toString()));
    } else if (map['roleId'] != null) {
      roleIds.add(map['roleId'].toString());
    }

    return EnterpriseModuleUser(
      userId: map['userId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      moduleId: map['moduleId'] as String? ?? '',
      roleIds: roleIds,
      customPermissions:
          (map['customPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      isActive: map['isActive'] as bool? ?? true,
      includesChildren: map['includesChildren'] as bool? ?? false,
      parentEnterpriseId: map['parentEnterpriseId'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Génère un ID unique pour Firestore
  /// Format: {userId}_{enterpriseId}_{moduleId}
  String get documentId => '${userId}_${enterpriseId}_$moduleId';

  /// Convertit un timestamp Firestore (Timestamp ou String) en DateTime
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  @override
  String toString() {
    return 'EnterpriseModuleUser(userId: $userId, enterpriseId: $enterpriseId, '
        'moduleId: $moduleId, roleIds: $roleIds, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnterpriseModuleUser &&
        other.userId == userId &&
        other.enterpriseId == enterpriseId &&
        other.moduleId == moduleId;
  }

  @override
  int get hashCode => Object.hash(userId, enterpriseId, moduleId);
}

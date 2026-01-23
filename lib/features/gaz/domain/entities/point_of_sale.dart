/// Représente un point de vente.
///
/// Un point de vente est maintenant traité comme une entreprise à part entière
/// avec le module gaz activé. Il a une référence à l'entreprise mère (parentEnterpriseId)
/// pour rester accessible depuis les sections du module gaz de l'entreprise mère.
class PointOfSale {
  const PointOfSale({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.parentEnterpriseId,
    required this.moduleId,
    this.isActive = true,
    this.cylinderIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// ID du point de vente (identique à l'ID de l'Enterprise créée)
  final String id;
  final String name;
  final String address;
  final String contact; // Numéro de téléphone
  /// ID de l'entreprise mère (ex: 'gaz_1')
  /// Utilisé pour le stockage dans Drift et l'accès depuis l'entreprise mère
  final String parentEnterpriseId;
  final String moduleId;
  final bool isActive;
  final List<String>
  cylinderIds; // IDs des types de bouteilles associés à ce point de vente
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Getter pour compatibilité avec le code existant
  /// Retourne parentEnterpriseId pour maintenir la compatibilité
  String get enterpriseId => parentEnterpriseId;

  PointOfSale copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
    String? parentEnterpriseId,
    String? moduleId,
    bool? isActive,
    List<String>? cylinderIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PointOfSale(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      parentEnterpriseId: parentEnterpriseId ?? this.parentEnterpriseId,
      moduleId: moduleId ?? this.moduleId,
      isActive: isActive ?? this.isActive,
      cylinderIds: cylinderIds ?? this.cylinderIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ajoute un type de bouteille à ce point de vente.
  PointOfSale addCylinder(String cylinderId) {
    if (cylinderIds.contains(cylinderId)) return this;
    return copyWith(
      cylinderIds: [...cylinderIds, cylinderId],
      updatedAt: DateTime.now(),
    );
  }

  /// Retire un type de bouteille de ce point de vente.
  PointOfSale removeCylinder(String cylinderId) {
    if (!cylinderIds.contains(cylinderId)) return this;
    return copyWith(
      cylinderIds: cylinderIds.where((id) => id != cylinderId).toList(),
      updatedAt: DateTime.now(),
    );
  }
}

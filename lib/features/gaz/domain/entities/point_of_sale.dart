/// Représente un point de vente.
class PointOfSale {
  const PointOfSale({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.enterpriseId,
    required this.moduleId,
    this.isActive = true,
    this.cylinderIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final String contact; // Numéro de téléphone
  final String enterpriseId;
  final String moduleId;
  final bool isActive;
  final List<String> cylinderIds; // IDs des types de bouteilles associés à ce point de vente
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PointOfSale copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
    String? enterpriseId,
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
      enterpriseId: enterpriseId ?? this.enterpriseId,
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


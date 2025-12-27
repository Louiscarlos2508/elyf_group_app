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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


/// Représente une bouteille de gaz.
class Cylinder {
  const Cylinder({
    required this.id,
    required this.weight,
    required this.buyPrice,
    required this.sellPrice,
    required this.enterpriseId,
    required this.moduleId,
    this.stock = 0,
  });

  final String id;
  final int weight; // Poids en kg (dynamique, récupéré depuis les bouteilles créées)
  final double buyPrice;
  final double sellPrice;
  final String enterpriseId;
  final String moduleId;
  final int stock; // Stock disponible

  Cylinder copyWith({
    String? id,
    int? weight,
    double? buyPrice,
    double? sellPrice,
    String? enterpriseId,
    String? moduleId,
    int? stock,
  }) {
    return Cylinder(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      stock: stock ?? this.stock,
    );
  }

  String get label {
    return '${weight}kg';
  }
}

/// Statut d'une bouteille dans le circuit logistique.
enum CylinderStatus {
  full('Pleines'),
  emptyAtStore('Vides (Magasin)'),
  emptyInTransit('Vides (En transit)'),
  defective('Défectueuses'),
  leak('Fuites');

  const CylinderStatus(this.label);
  final String label;
}

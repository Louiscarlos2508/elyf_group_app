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
  final int weight; // Poids en kg: 3, 6, 10, 12
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

  /// Returns the cylinder type based on weight.
  CylinderWeight get type {
    switch (weight) {
      case 3:
        return CylinderWeight.threeKg;
      case 6:
        return CylinderWeight.sixKg;
      case 10:
        return CylinderWeight.tenKg;
      case 12:
        return CylinderWeight.twelveKg;
      default:
        return CylinderWeight.threeKg;
    }
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

/// Poids disponibles pour les bouteilles.
enum CylinderWeight {
  threeKg(3, '3 kg'),
  sixKg(6, '6 kg'),
  tenKg(10, '10 kg'),
  twelveKg(12, '12 kg');

  const CylinderWeight(this.value, this.label);
  final int value;
  final String label;

  static List<int> get availableWeights => [3, 6, 10, 12];
}

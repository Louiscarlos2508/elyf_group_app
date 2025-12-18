/// Représente une bouteille de gaz.
class Cylinder {
  const Cylinder({
    required this.id,
    required this.type,
    required this.weight,
    required this.buyPrice,
    required this.sellPrice,
    this.stock = 0,
  });

  final String id;
  final CylinderType type;
  final double weight; // en kg
  final double buyPrice;
  final double sellPrice;
  final int stock;

  Cylinder copyWith({
    String? id,
    CylinderType? type,
    double? weight,
    double? buyPrice,
    double? sellPrice,
    int? stock,
  }) {
    return Cylinder(
      id: id ?? this.id,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
    );
  }
}

enum CylinderType {
  small('Petite', 6),
  medium('Moyenne', 12.5),
  large('Grande', 38);

  const CylinderType(this.label, this.defaultWeight);
  final String label;
  final double defaultWeight;
}

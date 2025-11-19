/// Represents a product (finished good or raw material).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.isActive,
    this.price,
  });

  final String id;
  final String name;
  final ProductType type;
  final String unit;
  final bool isActive;
  final int? price;

  bool get isFinishedGood => type == ProductType.finishedGood;
  bool get isRawMaterial => type == ProductType.rawMaterial;
}

enum ProductType { finishedGood, rawMaterial }

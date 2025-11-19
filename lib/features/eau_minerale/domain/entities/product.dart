/// Product entity for catalog management (raw materials and finished goods).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.unitPrice,
    required this.unit,
    this.description,
  });

  final String id;
  final String name;
  final ProductType type;
  final int unitPrice; // Price in CFA
  final String unit;
  final String? description;

  bool get isRawMaterial => type == ProductType.rawMaterial;
  bool get isFinishedGood => type == ProductType.finishedGood;

  String get typeLabel => type == ProductType.rawMaterial ? 'MP' : 'PF';
  String get typeFullLabel =>
      type == ProductType.rawMaterial ? 'Matière Première' : 'Produit Fini';

  String get managementDescription {
    if (isRawMaterial) {
      return 'Géré manuellement • Utilisé en production';
    }
    return 'Ajouté par production • Déduit par ventes';
  }
}

enum ProductType { rawMaterial, finishedGood }

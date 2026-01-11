/// Represents a product in the boutique.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.category,
    this.imageUrl,
    this.barcode,
    this.purchasePrice, // Prix d'achat en CFA
    this.deletedAt, // Date de suppression (soft delete)
    this.deletedBy, // ID de l'utilisateur qui a supprimé
  });

  final String id;
  final String name;
  final int price; // Prix de vente en CFA
  final int stock; // Quantité disponible
  final String? description;
  final String? category;
  final String? imageUrl;
  final String? barcode; // Pour le scan de code-barres
  final int? purchasePrice; // Prix d'achat en CFA
  final DateTime? deletedAt; // Date de suppression (soft delete)
  final String? deletedBy; // ID de l'utilisateur qui a supprimé

  /// Indique si le produit est supprimé (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Calcule la marge bénéficiaire (prix de vente - prix d'achat)
  int? get profitMargin {
    if (purchasePrice == null) return null;
    return price - purchasePrice!;
  }

  /// Calcule le pourcentage de marge
  double? get profitMarginPercentage {
    if (purchasePrice == null || purchasePrice == 0) return null;
    return ((price - purchasePrice!) / purchasePrice!) * 100;
  }

  Product copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    String? description,
    String? category,
    String? imageUrl,
    String? barcode,
    int? purchasePrice,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}


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
    );
  }
}


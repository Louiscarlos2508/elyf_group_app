/// Represents a product in the boutique.
class Product {
  const Product({
    required this.id,
    required this.enterpriseId,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.categoryId,
    this.imageUrl,
    this.barcode,
    this.purchasePrice, // Prix d'achat en CFA
    this.lowStockThreshold = 5, // Seuil d'alerte par défaut
    this.isActive = true, // Produit actif ou archivé
    this.deletedAt, // Date de suppression (soft delete)
    this.deletedBy, // ID de l'utilisateur qui a supprimé
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final String name;
  final int price; // Prix de vente en CFA
  final int stock; // Quantité disponible
  final String? description;
  final String? categoryId;
  final String? imageUrl;
  final String? barcode; // Pour le scan de code-barres
  final int? purchasePrice; // Prix d'achat en CFA
  final int lowStockThreshold; // Seuil d'alerte
  final bool isActive;
  final DateTime? deletedAt; // Date de suppression (soft delete)
  final String? deletedBy; // ID de l'utilisateur qui a supprimé
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    String? enterpriseId,
    String? name,
    int? price,
    int? stock,
    String? description,
    String? categoryId,
    String? imageUrl,
    String? barcode,
    int? purchasePrice,
    int? lowStockThreshold,
    bool? isActive,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    DateTime? deletedAt;
    if (map['deletedAt'] != null) {
      deletedAt = map['deletedAt'] is DateTime
          ? map['deletedAt'] as DateTime
          : DateTime.parse(map['deletedAt'] as String);
    }
    return Product(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      name: map['name'] as String,
      price:
          (map['price'] as num?)?.toInt() ??
          (map['sellingPrice'] as num?)?.toInt() ??
          0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      description: map['description'] as String?,
      categoryId: map['categoryId'] as String? ?? map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      barcode: map['barcode'] as String?,
      purchasePrice: (map['purchasePrice'] as num?)?.toInt(),
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
      isActive: map['isActive'] as bool? ?? true,
      deletedAt: deletedAt,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'price': price,
      'sellingPrice': price,
      'stock': stock.toDouble(),
      'description': description,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'purchasePrice': purchasePrice?.toDouble(),
      'lowStockThreshold': lowStockThreshold.toDouble(),
      'isActive': isActive,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

import '../../domain/entities/product.dart';
import '../../domain/pack_constants.dart';
import '../../domain/repositories/product_repository.dart';

/// Controller pour gérer les produits.
class ProductController {
  ProductController(this._repository, this.enterpriseId);

  final ProductRepository _repository;
  final String enterpriseId;

  Future<Product> ensurePackProduct() async {
    final products = await _repository.fetchProducts();
    Product? pack;
    try {
      pack = products.firstWhere(
        (p) =>
            p.id == packProductId ||
            (p.isFinishedGood &&
                p.name.toLowerCase().contains(packName.toLowerCase())),
      );
    } catch (_) {
      pack = null;
    }

    if (pack != null) {
      if (pack.id != packProductId) {
        final updatedPack = pack.copyWith(id: packProductId);
        // We don't necessarily need to save it back to repo with NEW id if we map it in fetch
        // but it's cleaner to have a consistent record.
        // However, record replacement safely:
        return updatedPack;
      }
      return pack;
    }

    final defaultPack = Product(
      id: packProductId,
      enterpriseId: enterpriseId,
      name: packName,
      type: ProductType.finishedGood,
      unitPrice: 200,
      unit: packUnit,
      description: 'Pack de bouteilles d\'eau minérale',
    );
    await _repository.createProduct(defaultPack);
    return defaultPack;
  }

  Future<void> ensureDefaultRawMaterials() async {
    final products = await _repository.fetchProducts();
    
    // Ensure Bobine
    final hasBobine = products.any((p) => p.id == bobineProductId || (p.isRawMaterial && p.name.toLowerCase() == bobineName.toLowerCase()));
    if (!hasBobine) {
      final bobine = Product(
        id: bobineProductId,
        enterpriseId: enterpriseId,
        name: bobineName,
        type: ProductType.rawMaterial,
        unitPrice: 0,
        unit: 'unité',
        description: 'Bobine de film plastique pour sachets',
      );
      await _repository.createProduct(bobine);
    }

    // Ensure Emballage
    final hasEmballage = products.any((p) => p.id == emballageProductId || (p.isRawMaterial && p.name.toLowerCase() == emballageName.toLowerCase()));
    if (!hasEmballage) {
      final emballage = Product(
        id: emballageProductId,
        enterpriseId: enterpriseId,
        name: emballageName,
        type: ProductType.rawMaterial,
        unitPrice: 0,
        unit: 'unité',
        supplyUnit: 'Paquet',
        unitsPerLot: emballageDefaultUnitsPerLot,
        description: 'Sacs d\'emballage pour les packs',
      );
      await _repository.createProduct(emballage);
    }
  }

  /// Récupère tous les produits. Garantit la présence du Pack et des matières premières par défaut.
  /// Le Pack est toujours retourné avec [packProductId] pour aligner Stock / Ventes.
  Future<List<Product>> fetchProducts() async {
    await ensurePackProduct();
    await ensureDefaultRawMaterials();
    final list = await _repository.fetchProducts();
    final mapped = list.map((p) {
      if (p.isFinishedGood &&
          p.name.toLowerCase().contains(packName.toLowerCase()) &&
          p.id != packProductId) {
        return p.copyWith(id: packProductId);
      }
      return p;
    }).toList();

    // Dédupliquer par ID pour éviter les doublons de Pack
    final seen = <String>{};
    return mapped.where((p) => seen.add(p.id)).toList();
  }

  /// Récupère un produit par son ID.
  Future<Product?> getProduct(String id) async {
    return await _repository.getProduct(id);
  }

  /// Crée un nouveau produit.
  Future<String> createProduct(Product product) async {
    return await _repository.createProduct(product);
  }

  /// Met à jour un produit existant.
  Future<void> updateProduct(Product product) async {
    return await _repository.updateProduct(product);
  }

  /// Supprime un produit.
  Future<void> deleteProduct(String id) async {
    return await _repository.deleteProduct(id);
  }
}

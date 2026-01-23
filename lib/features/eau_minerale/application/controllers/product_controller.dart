import '../../domain/entities/product.dart';
import '../../domain/pack_constants.dart';
import '../../domain/repositories/product_repository.dart';

/// Controller pour gérer les produits.
class ProductController {
  ProductController(this._repository);

  final ProductRepository _repository;

  /// Garantit l'existence du produit Pack. Le crée avec prix 200 CFA si absent.
  /// Retourne toujours un [Product] avec [packProductId] pour aligner Stock / Ventes.
  Future<Product> ensurePackProduct() async {
    final all = await _repository.fetchProducts();
    Product? pack;
    try {
      pack = all.firstWhere((p) =>
          p.isFinishedGood &&
          p.name.toLowerCase().contains(packName.toLowerCase()));
    } catch (_) {}
    if (pack != null) {
      if (pack.id != packProductId) {
        return Product(
          id: packProductId,
          name: pack.name,
          type: pack.type,
          unitPrice: pack.unitPrice,
          unit: pack.unit,
          description: pack.description,
        );
      }
      return pack;
    }
    const defaultPack = Product(
      id: packProductId,
      name: packName,
      type: ProductType.finishedGood,
      unitPrice: 200,
      unit: packUnit,
      description: null,
    );
    await _repository.createProduct(defaultPack);
    return defaultPack;
  }

  /// Récupère tous les produits. Garantit la présence du Pack.
  /// Le Pack est toujours retourné avec [packProductId] pour aligner Stock / Ventes.
  Future<List<Product>> fetchProducts() async {
    await ensurePackProduct();
    final list = await _repository.fetchProducts();
    return list.map((p) {
      if (p.isFinishedGood &&
          p.name.toLowerCase().contains(packName.toLowerCase()) &&
          p.id != packProductId) {
        return Product(
          id: packProductId,
          name: p.name,
          type: p.type,
          unitPrice: p.unitPrice,
          unit: p.unit,
          description: p.description,
        );
      }
      return p;
    }).toList();
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

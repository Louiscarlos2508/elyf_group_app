import '../entities/product.dart';
import '../entities/production.dart';
import '../repositories/production_repository.dart';
import '../repositories/stock_repository.dart';
import '../repositories/product_repository.dart';

/// Business logic service for production with automatic stock updates.
class ProductionService {
  const ProductionService({
    required this.productionRepository,
    required this.stockRepository,
    required this.productRepository,
  });

  final ProductionRepository productionRepository;
  final StockRepository stockRepository;
  final ProductRepository productRepository;

  /// Creates a production and updates stocks automatically.
  Future<String> createProduction(Production production) async {
    // Validate raw materials stock if provided
    if (production.rawMaterialsUsed != null) {
      for (final material in production.rawMaterialsUsed!) {
        final currentStock = await stockRepository.getStock(material.productId);
        if (currentStock < material.quantity) {
          throw Exception(
            'Stock insuffisant pour ${material.productName}. Disponible: $currentStock ${material.unit}',
          );
        }
      }
    }

    // Create production record
    final productionId = await productionRepository.createProduction(
      production,
    );

    // Update finished goods stock (find first active finished good product)
    final finishedGoods = await productRepository.fetchActiveProducts(
      ProductType.finishedGood,
    );
    if (finishedGoods.isNotEmpty) {
      final product = finishedGoods.first;
      final currentStock = await stockRepository.getStock(product.id);
      await stockRepository.updateStock(
        product.id,
        currentStock + production.quantity,
      );
    }

    // Deduct raw materials if provided
    if (production.rawMaterialsUsed != null) {
      for (final material in production.rawMaterialsUsed!) {
        final currentStock = await stockRepository.getStock(material.productId);
        await stockRepository.updateStock(
          material.productId,
          currentStock - material.quantity,
        );
      }
    }

    return productionId;
  }
}

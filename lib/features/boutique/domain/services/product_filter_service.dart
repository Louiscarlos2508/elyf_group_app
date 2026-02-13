import '../entities/product.dart';

/// Service for filtering products.
///
/// Extracts product filtering logic from UI widgets to make it testable and reusable.
class ProductFilterService {
  /// Filters products by search query.
  ///
  /// Searches in product name, category name (if provided), and barcode.
  static List<Product> filterProducts({
    required List<Product> products,
    required String query,
    Map<String, String>? categoryNames, // productId -> categoryName
  }) {
    if (query.isEmpty) return products;

    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      final categoryName = categoryNames?[product.categoryId] ?? '';
      return product.name.toLowerCase().contains(lowerQuery) ||
          (categoryName.toLowerCase().contains(lowerQuery)) ||
          (product.barcode?.contains(query) ?? false);
    }).toList();
  }

  /// Filters products by category ID.
  static List<Product> filterByCategory({
    required List<Product> products,
    required String categoryId,
  }) {
    return products.where((product) => product.categoryId == categoryId).toList();
  }

  /// Filters products by stock status.
  static List<Product> filterByStockStatus({
    required List<Product> products,
    required bool inStock,
  }) {
    if (inStock) {
      return products.where((product) => product.stock > 0).toList();
    } else {
      return products.where((product) => product.stock <= 0).toList();
    }
  }

  /// Filters low stock products.
  static List<Product> filterLowStock({
    required List<Product> products,
    int threshold = 10,
  }) {
    return products.where((product) => product.stock <= threshold).toList();
  }

  /// Combines multiple filters.
  static List<Product> applyFilters({
    required List<Product> products,
    String? searchQuery,
    String? category,
    bool? inStock,
    int? lowStockThreshold,
  }) {
    var filtered = products;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filterProducts(products: filtered, query: searchQuery);
    }

    if (category != null) {
      filtered = filterByCategory(products: filtered, categoryId: category);
    }

    if (inStock != null) {
      filtered = filterByStockStatus(products: filtered, inStock: inStock);
    }

    if (lowStockThreshold != null) {
      filtered = filterLowStock(
        products: filtered,
        threshold: lowStockThreshold,
      );
    }

    return filtered;
  }
}

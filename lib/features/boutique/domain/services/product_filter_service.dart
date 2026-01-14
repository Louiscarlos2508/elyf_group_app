import '../entities/product.dart';

/// Service for filtering products.
///
/// Extracts product filtering logic from UI widgets to make it testable and reusable.
class ProductFilterService {
  /// Filters products by search query.
  ///
  /// Searches in product name, category, and barcode.
  static List<Product> filterProducts({
    required List<Product> products,
    required String query,
  }) {
    if (query.isEmpty) return products;

    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          (product.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (product.barcode?.contains(query) ?? false);
    }).toList();
  }

  /// Filters products by category.
  static List<Product> filterByCategory({
    required List<Product> products,
    required String category,
  }) {
    return products.where((product) => product.category == category).toList();
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
      filtered = filterByCategory(products: filtered, category: category);
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

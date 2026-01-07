/// Service for product-related calculations.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ProductCalculationService {
  ProductCalculationService();

  /// Calculates unit purchase price from total purchase price and stock.
  ///
  /// Returns null if stock is 0 or totalPurchasePrice is null.
  int? calculateUnitPurchasePrice({
    required int stockInitial,
    int? totalPurchasePrice,
  }) {
    if (stockInitial > 0 && totalPurchasePrice != null) {
      return (totalPurchasePrice / stockInitial).round();
    }
    return null;
  }

  /// Validates product data.
  ///
  /// Returns null if valid, error message otherwise.
  String? validateProduct({
    required String? name,
    required String? price,
    required int? stock,
  }) {
    if (name == null || name.trim().isEmpty) {
      return 'Le nom du produit est requis';
    }

    if (price == null || price.trim().isEmpty) {
      return 'Le prix de vente est requis';
    }

    final priceValue = int.tryParse(price);
    if (priceValue == null || priceValue <= 0) {
      return 'Le prix de vente doit être un nombre positif';
    }

    if (stock != null && stock < 0) {
      return 'Le stock ne peut pas être négatif';
    }

    return null;
  }
}


/// Service for validating product data.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ProductValidationService {
  ProductValidationService();

  /// Validates product name.
  String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Requis';
    }
    return null;
  }

  /// Validates product price.
  String? validatePrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'Requis';
    }
    final priceValue = int.tryParse(price);
    if (priceValue == null || priceValue < 0) {
      return 'Prix invalide';
    }
    return null;
  }

  /// Validates product unit.
  String? validateUnit(String? unit) {
    if (unit == null || unit.isEmpty) {
      return 'Requis';
    }
    return null;
  }
}


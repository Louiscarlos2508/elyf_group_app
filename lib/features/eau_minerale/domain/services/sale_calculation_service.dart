import '../entities/product.dart';

/// Service for sale calculation logic.
///
/// Extracts calculation logic from UI widgets to make it testable and reusable.
class SaleCalculationService {
  /// Calculates the total price for a sale.
  ///
  /// Returns null if unitPrice or quantity is null.
  static int? calculateTotalPrice({int? unitPrice, int? quantity}) {
    if (unitPrice == null || quantity == null) {
      return null;
    }
    return unitPrice * quantity;
  }

  /// Calculates the total price from a product and quantity.
  ///
  /// Returns null if product is null or quantity is invalid.
  static int? calculateTotalPriceFromProduct({
    Product? product,
    int? quantity,
  }) {
    if (product == null || quantity == null) {
      return null;
    }
    return calculateTotalPrice(
      unitPrice: product.unitPrice,
      quantity: quantity,
    );
  }

  /// Calculates the remaining credit amount.
  ///
  /// Returns 0 if fully paid or overpaid.
  static int calculateRemainingCredit({
    required int totalPrice,
    required int amountPaid,
  }) {
    final remaining = totalPrice - amountPaid;
    return remaining > 0 ? remaining : 0;
  }

  /// Checks if a sale is fully paid.
  static bool isFullyPaid({required int totalPrice, required int amountPaid}) {
    return amountPaid >= totalPrice;
  }

  /// Checks if a sale has credit (partial payment).
  static bool hasCredit({required int totalPrice, required int amountPaid}) {
    return amountPaid < totalPrice;
  }

  /// Validates that amount paid does not exceed total price.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAmountPaid({
    required int? totalPrice,
    required int? amountPaid,
  }) {
    if (amountPaid == null) {
      return 'Montant invalide';
    }
    if (amountPaid < 0) {
      return 'Le montant ne peut pas être négatif';
    }
    if (totalPrice != null && amountPaid > totalPrice) {
      return 'Le montant payé ne peut pas dépasser le total';
    }
    return null;
  }

  /// Gets the unit price from a product.
  static int? getUnitPrice(Product? product) {
    return product?.unitPrice;
  }
}

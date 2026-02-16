import '../entities/cylinder.dart';
import '../entities/gaz_settings.dart';

/// Service for gas sale calculation logic.
///
/// Extracts calculation logic from UI widgets to make it testable and reusable.
class GasCalculationService {
  /// Calculates total amount for a gas sale.
  ///
  /// Returns 0.0 if cylinder is null or unitPrice is 0.0.
  static double calculateTotalAmount({
    required Cylinder? cylinder,
    required double unitPrice,
    required int quantity,
    int emptyReturnedQuantity = 0,
  }) {
    if (cylinder == null || (unitPrice == 0.0 && cylinder.depositPrice == 0.0) || quantity < 0) {
      return 0.0;
    }
    
    final gasTotal = unitPrice * quantity;
    final depositDifference = quantity - emptyReturnedQuantity;
    final depositTotal = depositDifference * cylinder.depositPrice;
    
    return gasTotal + depositTotal;
  }

  /// Calculates total amount from quantity text input.
  ///
  /// Returns 0.0 if cylinder is null, unitPrice is 0.0, or quantityText is invalid.
  static double calculateTotalAmountFromText({
    required Cylinder? cylinder,
    required double unitPrice,
    required String? quantityText,
    int emptyReturnedQuantity = 0,
  }) {
    if (cylinder == null ||
        (unitPrice == 0.0 && cylinder.depositPrice == 0.0) ||
        quantityText == null ||
        quantityText.isEmpty) {
      return 0.0;
    }
    final quantity = int.tryParse(quantityText) ?? 0;
    return calculateTotalAmount(
      cylinder: cylinder,
      unitPrice: unitPrice,
      quantity: quantity,
      emptyReturnedQuantity: emptyReturnedQuantity,
    );
  }

  /// Calculates profit for a gas sale.
  ///
  /// Returns 0.0 if purchase price is not available.
  static double calculateProfit({
    required double sellPrice,
    required double? purchasePrice,
    required int quantity,
  }) {
    if (purchasePrice == null || purchasePrice <= 0) {
      return 0.0;
    }
    final profitPerUnit = sellPrice - purchasePrice;
    return profitPerUnit * quantity;
  }

  /// Calculates profit margin percentage.
  ///
  /// Returns 0.0 if sellPrice is 0 or purchasePrice is null/invalid.
  static double calculateProfitMargin({
    required double sellPrice,
    required double? purchasePrice,
  }) {
    if (sellPrice == 0 || purchasePrice == null || purchasePrice <= 0) {
      return 0.0;
    }
    final profit = sellPrice - purchasePrice;
    return (profit / purchasePrice) * 100;
  }

  /// Validates that quantity is within available stock.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateQuantity({
    required int? quantity,
    required int availableStock,
  }) {
    if (quantity == null) {
      return 'Veuillez entrer une quantité';
    }
    if (quantity <= 0) {
      return 'Quantité invalide';
    }
    if (quantity > availableStock) {
      return 'Stock insuffisant ($availableStock disponible)';
    }
    return null;
  }

  /// Validates that quantity text is valid.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateQuantityText({
    required String? quantityText,
    required int availableStock,
  }) {
    if (quantityText == null || quantityText.isEmpty) {
      return 'Veuillez entrer une quantité';
    }
    final quantity = int.tryParse(quantityText);
    return validateQuantity(quantity: quantity, availableStock: availableStock);
  }

  /// Determines the wholesale price based on settings and tier.
  /// 
  /// Falls back to cylinder's sell price if no wholesale price is defined.
  static double determineWholesalePrice({
    required Cylinder cylinder,
    required GazSettings? settings,
    String tier = 'default',
  }) {
    if (settings == null) {
      return cylinder.sellPrice;
    }
    
    return settings.getWholesalePrice(cylinder.weight, tier: tier) ?? cylinder.sellPrice;
  }
}

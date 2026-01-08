import '../../entities/cart_item.dart';

/// Service for calculating cart metrics for the Boutique module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class CartCalculationService {
  CartCalculationService();

  /// Calculates total cart amount.
  int calculateCartTotal(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// Calculates total item count in cart.
  int calculateCartItemCount(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Calculates change amount (amount paid - total).
  int calculateChange({
    required int amountPaid,
    required int total,
  }) {
    if (amountPaid > total) {
      return amountPaid - total;
    }
    return 0;
  }

  /// Calculates remaining amount (total - amount paid).
  int calculateRemaining({
    required int total,
    required int amountPaid,
  }) {
    final remaining = total - amountPaid;
    return remaining > 0 ? remaining : 0;
  }
}


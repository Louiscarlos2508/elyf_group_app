import '../entities/cart_item.dart';
import '../entities/product.dart';

/// Service for cart management logic.
///
/// Extracts cart management logic from UI widgets to make it testable and reusable.
class CartService {
  /// Validates if a product can be added to cart.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAddToCart({
    required Product product,
    required int quantity,
  }) {
    if (product.stock <= 0) {
      return 'Produit en rupture de stock';
    }
    if (quantity > product.stock) {
      return 'Stock insuffisant';
    }
    return null;
  }

  /// Validates if quantity can be updated in cart.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateUpdateQuantity({
    required Product product,
    required int quantity,
  }) {
    if (quantity <= 0) {
      return 'La quantité doit être supérieure à 0';
    }
    if (quantity > product.stock) {
      return 'Stock insuffisant';
    }
    return null;
  }

  /// Finds existing cart item for a product.
  static CartItem? findCartItem({
    required List<CartItem> cartItems,
    required Product product,
  }) {
    try {
      return cartItems.firstWhere(
        (item) => item.product.id == product.id,
      );
    } catch (_) {
      return null;
    }
  }

  /// Adds a product to cart or updates quantity if already present.
  ///
  /// Returns the updated cart items list.
  static List<CartItem> addToCart({
    required List<CartItem> cartItems,
    required Product product,
    int quantity = 1,
  }) {
    final existingItem = findCartItem(
      cartItems: cartItems,
      product: product,
    );

    if (existingItem != null) {
      // Update existing item
      final newQuantity = existingItem.quantity + quantity;
      if (newQuantity <= product.stock) {
        final updatedItems = List<CartItem>.from(cartItems);
        final index = updatedItems.indexOf(existingItem);
        updatedItems[index] = existingItem.copyWith(quantity: newQuantity);
        return updatedItems;
      }
      // Cannot add more, return original list
      return cartItems;
    } else {
      // Add new item
      if (product.stock >= quantity) {
        return [...cartItems, CartItem(product: product, quantity: quantity)];
      }
      // Cannot add, return original list
      return cartItems;
    }
  }

  /// Updates quantity of a cart item.
  ///
  /// Returns the updated cart items list, or null if item should be removed.
  static List<CartItem>? updateCartItemQuantity({
    required List<CartItem> cartItems,
    required int itemIndex,
    required int newQuantity,
  }) {
    if (newQuantity <= 0) {
      // Remove item
      final updatedItems = List<CartItem>.from(cartItems);
      updatedItems.removeAt(itemIndex);
      return updatedItems;
    }

    final item = cartItems[itemIndex];
    if (newQuantity <= item.product.stock) {
      final updatedItems = List<CartItem>.from(cartItems);
      updatedItems[itemIndex] = item.copyWith(quantity: newQuantity);
      return updatedItems;
    }

    // Cannot update, return null to indicate error
    return null;
  }

  /// Removes an item from cart.
  static List<CartItem> removeFromCart({
    required List<CartItem> cartItems,
    required int itemIndex,
  }) {
    final updatedItems = List<CartItem>.from(cartItems);
    updatedItems.removeAt(itemIndex);
    return updatedItems;
  }

  /// Clears the cart.
  static List<CartItem> clearCart() {
    return [];
  }

  /// Validates that cart is not empty.
  static String? validateCartNotEmpty(List<CartItem> cartItems) {
    if (cartItems.isEmpty) {
      return 'Le panier est vide';
    }
    return null;
  }
}


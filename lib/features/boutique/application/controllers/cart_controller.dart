import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      // On ne vérifie le stock ici que si on veut bloquer l'ajout au-delà du stock.
      // Idéalement, l'UI devrait aussi empêcher cela.
      // Pour une logique robuste, on pourrait vérifier ici.
      if (existing.quantity + quantity <= product.stock) {
        final updatedItems = [...state];
        updatedItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
        state = updatedItems;
      } else {
        // Optionnel : Throw une exception ou gérer l'erreur via un callback
        // Pour l'instant on ne fait rien si stock insuffisant
      }
    } else {
      if (product.stock >= quantity) {
        state = [...state, CartItem(product: product, quantity: quantity)];
      }
    }
  }

  void removeFromCart(CartItem item) {
    state = state.where((i) => i.product.id != item.product.id).toList();
  }

  void removeFromCartAtIndex(int index) {
    if (index >= 0 && index < state.length) {
      final updated = [...state];
      updated.removeAt(index);
      state = updated;
    }
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= state.length) return;
    
    if (quantity <= 0) {
      removeFromCartAtIndex(index);
      return;
    }

    final item = state[index];
    if (quantity <= item.product.stock) {
      final updated = [...state];
      updated[index] = item.copyWith(quantity: quantity);
      state = updated;
    }
  }

  void clearCart() {
    state = [];
  }
}

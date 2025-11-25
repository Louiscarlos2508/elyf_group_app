/// Represents a purchase (achat) of products for the boutique.
class Purchase {
  const Purchase({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.supplier,
    this.notes,
  });

  final String id;
  final DateTime date;
  final List<PurchaseItem> items;
  final int totalAmount; // Montant total en CFA
  final String? supplier; // Fournisseur
  final String? notes; // Notes additionnelles
}

/// Represents an item in a purchase.
class PurchaseItem {
  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice, // Prix d'achat unitaire
    required this.totalPrice, // Prix total pour cette quantité
  });

  final String productId;
  final String productName;
  final int quantity;
  final int purchasePrice;
  final int totalPrice;
}


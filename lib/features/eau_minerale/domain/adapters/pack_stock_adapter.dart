/// Abstrait l'accès au stock Pack (produits finis) pour ventes et validation.
abstract class PackStockAdapter {
  /// Retourne la quantité en stock pour le Pack ou un produit spécifique.
  Future<int> getPackStock({String? productId});

  /// Enregistre une sortie de stock pour le Pack ou un produit spécifique.
  Future<void> recordPackExit(
    int quantity, {
    String? productId,
    String? reason,
    String? notes,
  });
}

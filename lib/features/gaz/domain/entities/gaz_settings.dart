/// Paramètres de configuration du module Gaz.
class GazSettings {
  const GazSettings({
    required this.enterpriseId,
    required this.moduleId,
    this.wholesalePrices = const {},
    this.updatedAt,
  });

  final String enterpriseId;
  final String moduleId;
  final Map<int, double> wholesalePrices; // poids (kg) -> prix en gros (FCFA)
  final DateTime? updatedAt;

  GazSettings copyWith({
    String? enterpriseId,
    String? moduleId,
    Map<int, double>? wholesalePrices,
    DateTime? updatedAt,
  }) {
    return GazSettings(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      moduleId: moduleId ?? this.moduleId,
      wholesalePrices: wholesalePrices ?? this.wholesalePrices,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Récupère le prix en gros pour un poids donné.
  double? getWholesalePrice(int weight) {
    return wholesalePrices[weight];
  }

  /// Définit le prix en gros pour un poids donné.
  GazSettings setWholesalePrice(int weight, double price) {
    final updatedPrices = Map<int, double>.from(wholesalePrices);
    updatedPrices[weight] = price;
    return copyWith(wholesalePrices: updatedPrices, updatedAt: DateTime.now());
  }

  /// Supprime le prix en gros pour un poids donné.
  GazSettings removeWholesalePrice(int weight) {
    final updatedPrices = Map<int, double>.from(wholesalePrices);
    updatedPrices.remove(weight);
    return copyWith(wholesalePrices: updatedPrices, updatedAt: DateTime.now());
  }
}

import '../entities/collection.dart';

/// Service de calculs pour les collections.
class CollectionCalculationService {
  CollectionCalculationService._();

  /// Calcule le montant dû pour une collection après déduction des fuites.
  static double calculateAmountDue(Collection collection, Map<int, int> leaks) {
    double total = 0.0;
    for (final entry in collection.emptyBottles.entries) {
      final weight = entry.key;
      final qty = entry.value;
      final leakQty = leaks[weight] ?? 0;
      final validBottles = qty - leakQty;
      final price = collection.getUnitPriceForWeight(weight);
      total += validBottles * price;
    }
    // Soustraire ce qui a déjà été payé
    return (total - collection.amountPaid).clamp(0.0, double.infinity);
  }
}

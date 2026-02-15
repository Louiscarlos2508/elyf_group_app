/// Représente une alerte de stock.
class StockAlert {
  const StockAlert({
    required this.cylinderId,
    required this.weight,
    required this.currentStock,
    required this.threshold,
    required this.timestamp,
    this.isFullStock = true,
  });

  final String cylinderId;
  final int weight;
  final int currentStock;
  final int threshold;
  final DateTime timestamp;
  final bool isFullStock;

  String get message {
    final type = isFullStock ? 'pleines' : 'vides';
    return 'Attention : Stock de bouteilles $type de ${weight}kg bas ($currentStock < $threshold)';
  }
}

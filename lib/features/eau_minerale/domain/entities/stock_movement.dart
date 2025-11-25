/// Represents a stock movement (entry or exit).
class StockMovement {
  const StockMovement({
    required this.id,
    required this.date,
    required this.productName,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.unit,
  });

  final String id;
  final DateTime date;
  final String productName;
  final StockMovementType type;
  final String reason;
  final double quantity;
  final String unit;

  factory StockMovement.sample(int index) {
    final reasons = [
      'Production',
      'Vente',
      'Ajustement manuel',
      'Réception',
      'Perte',
    ];
    final products = [
      'Sachets',
      'Bidons',
      'Pack',
    ];
    
    return StockMovement(
      id: 'movement-$index',
      date: DateTime.now().subtract(Duration(days: index)),
      productName: products[index % products.length],
      type: index.isEven ? StockMovementType.entry : StockMovementType.exit,
      reason: reasons[index % reasons.length],
      quantity: (100 + index * 10).toDouble(),
      unit: index % 2 == 0 ? 'kg' : 'unité',
    );
  }
}

enum StockMovementType { entry, exit }

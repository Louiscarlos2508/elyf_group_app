/// Stock movement (entry, exit, or adjustment).
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.date,
    required this.reason,
    this.source,
  });

  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity;
  final DateTime date;
  final String reason;
  final String? source;
}

enum StockMovementType { entry, exit, adjustment }

/// Production record with period tracking.
class Production {
  const Production({
    required this.id,
    required this.date,
    required this.quantity,
    required this.period,
    this.rawMaterialsUsed,
    this.notes,
  });

  final String id;
  final DateTime date;
  final int quantity;
  final int period;
  final List<RawMaterialUsage>? rawMaterialsUsed;
  final String? notes;
}

class RawMaterialUsage {
  const RawMaterialUsage({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
  });

  final String productId;
  final String productName;
  final int quantity;
  final String unit;
}

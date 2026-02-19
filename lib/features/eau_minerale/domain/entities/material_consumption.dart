class MaterialConsumption {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final int unitsPerLot;

  const MaterialConsumption({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitsPerLot,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'unitsPerLot': unitsPerLot,
    };
  }

  factory MaterialConsumption.fromMap(Map<String, dynamic> map) {
    return MaterialConsumption(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitsPerLot: (map['unitsPerLot'] as num).toInt(),
    );
  }

  MaterialConsumption copyWith({
    String? productId,
    String? productName,
    double? quantity,
    String? unit,
    int? unitsPerLot,
  }) {
    return MaterialConsumption(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitsPerLot: unitsPerLot ?? this.unitsPerLot,
    );
  }
}

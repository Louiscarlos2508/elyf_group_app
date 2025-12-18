/// Représente une livraison/approvisionnement de bouteilles.
class Delivery {
  const Delivery({
    required this.id,
    required this.cylinderId,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.deliveryDate,
    this.supplierName,
    this.notes,
  });

  final String id;
  final String cylinderId;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final DateTime deliveryDate;
  final String? supplierName;
  final String? notes;

  Delivery copyWith({
    String? id,
    String? cylinderId,
    int? quantity,
    double? unitCost,
    double? totalCost,
    DateTime? deliveryDate,
    String? supplierName,
    String? notes,
  }) {
    return Delivery(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      supplierName: supplierName ?? this.supplierName,
      notes: notes ?? this.notes,
    );
  }
}

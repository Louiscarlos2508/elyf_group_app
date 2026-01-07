/// Represents a person to be paid in a production payment.
class ProductionPaymentPerson {
  const ProductionPaymentPerson({
    required this.name,
    required this.pricePerDay,
    required this.daysWorked,
    this.totalAmount,
  });

  final String name;
  final int pricePerDay; // Price per day in CFA
  final int daysWorked;
  final int? totalAmount; // Total amount (can be manually set or auto-calculated)

  /// Calculated total amount if not manually set.
  int get calculatedTotalAmount => pricePerDay * daysWorked;

  /// Actual total amount (manual or calculated).
  int get effectiveTotalAmount => totalAmount ?? calculatedTotalAmount;

  ProductionPaymentPerson copyWith({
    String? name,
    int? pricePerDay,
    int? daysWorked,
    int? totalAmount,
  }) {
    return ProductionPaymentPerson(
      name: name ?? this.name,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      daysWorked: daysWorked ?? this.daysWorked,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}


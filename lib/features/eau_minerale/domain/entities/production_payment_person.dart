/// Represents a person to be paid in a production payment.
class ProductionPaymentPerson {
  const ProductionPaymentPerson({
    required this.name,
    required this.pricePerDay,
    required this.daysWorked,
  });

  final String name;
  final int pricePerDay; // Price per day in CFA
  final int daysWorked;

  int get totalAmount => pricePerDay * daysWorked;
}


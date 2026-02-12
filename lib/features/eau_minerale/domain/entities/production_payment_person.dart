/// Represents a person to be paid in a production payment.
class ProductionPaymentPerson {
  const ProductionPaymentPerson({
    this.workerId,
    required this.name,
    required this.pricePerDay,
    required this.daysWorked,
    this.totalAmount,
  });

  final String? workerId;
  final String name;
  final int pricePerDay; // Price per day in CFA
  final int daysWorked;
  final int?
  totalAmount; // Total amount (can be manually set or auto-calculated)

  /// Calculated total amount if not manually set.
  int get calculatedTotalAmount => pricePerDay * daysWorked;

  /// Actual total amount (manual or calculated).
  int get effectiveTotalAmount => totalAmount ?? calculatedTotalAmount;

  ProductionPaymentPerson copyWith({
    String? workerId,
    String? name,
    int? pricePerDay,
    int? daysWorked,
    int? totalAmount,
  }) {
    return ProductionPaymentPerson(
      workerId: workerId ?? this.workerId,
      name: name ?? this.name,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      daysWorked: daysWorked ?? this.daysWorked,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  factory ProductionPaymentPerson.fromMap(Map<String, dynamic> map) {
    return ProductionPaymentPerson(
      workerId: map['workerId'] as String?,
      name: map['name'] as String? ?? '',
      pricePerDay: (map['pricePerDay'] as num?)?.toInt() ??
          (map['dailyRate'] as num?)?.toInt() ??
          0,
      daysWorked: (map['daysWorked'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'name': name,
      'pricePerDay': pricePerDay,
      'daysWorked': daysWorked,
      'totalAmount': totalAmount,
    };
  }
}

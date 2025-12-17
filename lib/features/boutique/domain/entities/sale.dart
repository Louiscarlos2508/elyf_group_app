/// Represents a completed sale transaction.
class Sale {
  const Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    this.customerName,
    this.paymentMethod,
    this.notes,
  });

  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final int totalAmount; // Total in CFA
  final int amountPaid; // Amount paid in CFA
  final String? customerName;
  final PaymentMethod? paymentMethod;
  final String? notes;

  int get change => amountPaid > totalAmount ? amountPaid - totalAmount : 0;
}

/// Represents an item in a sale.
class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
}

enum PaymentMethod {
  cash,
  mobileMoney,
}


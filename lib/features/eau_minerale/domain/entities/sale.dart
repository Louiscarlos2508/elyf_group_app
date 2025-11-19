/// Complete sale record with validation workflow.
class Sale {
  const Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.amountPaid,
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
    required this.date,
    required this.status,
    required this.createdBy,
    this.customerCnib,
    this.notes,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final int amountPaid;
  final String customerName;
  final String customerPhone;
  final String customerId;
  final DateTime date;
  final SaleStatus status;
  final String createdBy;
  final String? customerCnib;
  final String? notes;

  int get remainingAmount => totalPrice - amountPaid;
  bool get isCredit => remainingAmount > 0;
  bool get isFullyPaid => remainingAmount == 0;
  bool get isPending => status == SaleStatus.pending;
  bool get isValidated => status == SaleStatus.validated;
  bool get isRejected => status == SaleStatus.rejected;
}

enum SaleStatus { pending, validated, rejected, fullyPaid }

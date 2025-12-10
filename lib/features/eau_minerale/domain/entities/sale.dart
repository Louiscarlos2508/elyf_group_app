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
    this.cashAmount = 0,
    this.orangeMoneyAmount = 0,
    this.productionSessionId,
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
  final int cashAmount;
  final int orangeMoneyAmount;
  final String? productionSessionId; // Lien vers la session de production

  int get remainingAmount => totalPrice - amountPaid;
  bool get isCredit => remainingAmount > 0;
  bool get isFullyPaid => remainingAmount == 0;
  bool get isPending => status == SaleStatus.pending;
  bool get isValidated => status == SaleStatus.validated;
  bool get isRejected => status == SaleStatus.rejected;
  
  /// Vérifie si la somme des paiements correspond au montant payé
  bool get isPaymentSplitValid => 
      (cashAmount + orangeMoneyAmount) == amountPaid;
}

enum SaleStatus { pending, validated, rejected, fullyPaid }

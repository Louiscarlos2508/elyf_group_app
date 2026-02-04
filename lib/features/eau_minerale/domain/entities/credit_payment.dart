/// Represents a payment made against a credit sale.
class CreditPayment {
  const CreditPayment({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.date,
    required this.notes,
    this.cashAmount = 0,
    this.orangeMoneyAmount = 0,
    this.updatedAt,
  });

  final DateTime? updatedAt;

  final String id;
  final String saleId;
  final int amount;
  final DateTime date;
  final String? notes;
  final int cashAmount;
  final int orangeMoneyAmount;
}

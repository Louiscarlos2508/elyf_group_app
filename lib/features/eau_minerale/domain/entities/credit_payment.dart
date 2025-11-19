/// Represents a payment made against a credit sale.
class CreditPayment {
  const CreditPayment({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.date,
    required this.notes,
  });

  final String id;
  final String saleId;
  final int amount;
  final DateTime date;
  final String? notes;
}

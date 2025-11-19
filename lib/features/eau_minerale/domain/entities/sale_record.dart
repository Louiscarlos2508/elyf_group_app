/// Represents a sale or cash movement related to sachets of water.
class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.customer,
    required this.date,
    required this.amountCfa,
    required this.type,
    required this.quantity,
    required this.status,
  });

  final String id;
  final String customer;
  final DateTime date;
  final int amountCfa;
  final SaleType type;
  final int quantity;
  final SaleStatus status;

  factory SaleRecord.sample(int index) {
    return SaleRecord(
      id: 'sale-$index',
      customer: index.isEven ? 'Client Dépôt' : 'Client Crédit',
      date: DateTime.now().subtract(Duration(hours: index * 2)),
      amountCfa: 25000 + (index * 5200),
      type: SaleType.values[index % SaleType.values.length],
      quantity: 50 + (index * 5),
      status: index.isEven ? SaleStatus.paid : SaleStatus.pending,
    );
  }
}

enum SaleType { direct, credit, repayment }

enum SaleStatus { paid, pending, overdue }

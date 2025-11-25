/// Represents a credit entry for a customer.
class CustomerCredit {
  const CustomerCredit({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.amountPaid,
    required this.date,
    required this.dueDate,
  });

  final String id;
  final String saleId;
  final int amount;
  final int amountPaid;
  final DateTime date;
  final DateTime? dueDate;

  int get remainingAmount => amount - amountPaid;
  bool get isFullyPaid => remainingAmount == 0;
  
  factory CustomerCredit.sample(String id, int index) {
    return CustomerCredit(
      id: id,
      saleId: 'sale-$index',
      amount: 500 + (index * 200),
      amountPaid: index == 0 ? 0 : 100,
      date: DateTime.now().subtract(Duration(days: index + 5)),
      dueDate: DateTime.now().add(Duration(days: 30 - index * 5)),
    );
  }
}


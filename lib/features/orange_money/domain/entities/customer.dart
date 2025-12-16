/// Represents a Mobile Money customer.
class Customer {
  const Customer({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.email,
    this.totalTransactions = 0,
    this.totalAmount = 0,
    this.lastTransactionDate,
  });

  final String id;
  final String phoneNumber;
  final String name;
  final String? email;
  final int totalTransactions;
  final int totalAmount; // Total in FCFA
  final DateTime? lastTransactionDate;
}


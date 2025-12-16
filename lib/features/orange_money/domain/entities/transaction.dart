/// Represents a Mobile Money transaction (cash-in or cash-out).
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.phoneNumber,
    required this.date,
    required this.status,
    this.customerName,
    this.commission,
    this.fees,
    this.reference,
    this.notes,
    this.createdBy,
  });

  final String id;
  final TransactionType type;
  final int amount; // Amount in FCFA
  final String phoneNumber;
  final DateTime date;
  final TransactionStatus status;
  final String? customerName;
  final int? commission; // Commission earned in FCFA
  final int? fees; // Fees paid in FCFA
  final String? reference; // Transaction reference from Orange Money
  final String? notes;
  final String? createdBy;

  bool get isCashIn => type == TransactionType.cashIn;
  bool get isCashOut => type == TransactionType.cashOut;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isFailed => status == TransactionStatus.failed;
}

enum TransactionType {
  cashIn,
  cashOut,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}

extension TransactionTypeExtension on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.cashIn:
        return 'Cash-In';
      case TransactionType.cashOut:
        return 'Cash-Out';
    }
  }
}

extension TransactionStatusExtension on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Terminé';
      case TransactionStatus.failed:
        return 'Échoué';
    }
  }
}


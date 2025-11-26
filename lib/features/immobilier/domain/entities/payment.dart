import 'contract.dart';

/// Entité représentant un paiement de loyer.
class Payment {
  Payment({
    required this.id,
    required this.contractId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.contract,
    this.month,
    this.year,
    this.receiptNumber,
    this.notes,
    this.paymentType,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String contractId;
  final int amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final Contract? contract;
  final int? month;
  final int? year;
  final String? receiptNumber;
  final String? notes;
  final PaymentType? paymentType; // Type de paiement (loyer, caution, etc.)
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum PaymentType {
  rent, // Paiement de loyer
  deposit, // Paiement de caution
}

enum PaymentMethod {
  cash,
  mobileMoney,
  bankTransfer,
  check,
}

enum PaymentStatus {
  paid,
  pending,
  overdue,
  cancelled,
}


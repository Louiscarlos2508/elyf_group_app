import '../../../../shared/domain/entities/payment_method.dart';
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
    this.cashAmount,
    this.mobileMoneyAmount,
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
  final int? cashAmount; // Montant payé en espèces (si paymentMethod == both)
  final int?
  mobileMoneyAmount; // Montant payé en mobile money (si paymentMethod == both)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment copyWith({
    String? id,
    String? contractId,
    int? amount,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    Contract? contract,
    int? month,
    int? year,
    String? receiptNumber,
    String? notes,
    PaymentType? paymentType,
    int? cashAmount,
    int? mobileMoneyAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      contract: contract ?? this.contract,
      month: month ?? this.month,
      year: year ?? this.year,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      paymentType: paymentType ?? this.paymentType,
      cashAmount: cashAmount ?? this.cashAmount,
      mobileMoneyAmount: mobileMoneyAmount ?? this.mobileMoneyAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PaymentType {
  rent, // Paiement de loyer
  deposit, // Paiement de caution
}

enum PaymentStatus { paid, pending, overdue, cancelled }

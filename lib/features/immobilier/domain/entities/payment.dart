import '../../../../shared/domain/entities/payment_method.dart';
import 'contract.dart';

/// Entité représentant un paiement de loyer.
class Payment {
  Payment({
    required this.id,
    required this.enterpriseId,
    required this.contractId,
    required this.amount,
    required this.paidAmount,
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
    this.penaltyAmount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String contractId;
  final int amount; // Total amount due
  final int paidAmount; // Current amount paid
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
  final int penaltyAmount; // Accumulated penalty for late payment
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  Payment copyWith({
    String? id,
    String? enterpriseId,
    String? contractId,
    int? amount,
    int? paidAmount,
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
    int? penaltyAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Payment(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      contractId: contractId ?? this.contractId,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
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
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  /// Représentation sérialisable pour logs / audit trail / persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'contractId': contractId,
      'amount': amount,
      'paidAmount': paidAmount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'month': month,
      'year': year,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'paymentType': paymentType?.name,
      'cashAmount': cashAmount,
      'mobileMoneyAmount': mobileMoneyAmount,
      'penaltyAmount': penaltyAmount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String,
      contractId: map['contractId'] as String,
      amount: (map['amount'] as num).toInt(),
      paidAmount: (map['paidAmount'] as num?)?.toInt() ?? (map['amount'] as num).toInt(),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      month: (map['month'] as num?)?.toInt(),
      year: (map['year'] as num?)?.toInt(),
      receiptNumber: map['receiptNumber'] as String?,
      notes: map['notes'] as String?,
      paymentType: map['paymentType'] != null
          ? PaymentType.values.firstWhere(
              (e) => e.name == map['paymentType'],
              orElse: () => PaymentType.rent,
            )
          : null,
      cashAmount: (map['cashAmount'] as num?)?.toInt(),
      mobileMoneyAmount: (map['mobileMoneyAmount'] as num?)?.toInt(),
      penaltyAmount: (map['penaltyAmount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum PaymentType {
  rent, // Paiement de loyer
  deposit, // Paiement de caution
}

enum PaymentStatus { paid, partial, pending, overdue, cancelled }

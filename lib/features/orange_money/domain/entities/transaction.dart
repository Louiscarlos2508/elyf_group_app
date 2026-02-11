/// Represents a Mobile Money transaction (cash-in or cash-out).
class Transaction {
  const Transaction({
    required this.id,
    required this.enterpriseId,
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
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
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
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  Transaction copyWith({
    String? id,
    String? enterpriseId,
    TransactionType? type,
    int? amount,
    String? phoneNumber,
    DateTime? date,
    TransactionStatus? status,
    String? customerName,
    int? commission,
    int? fees,
    String? reference,
    String? notes,
    String? createdBy,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      commission: commission ?? this.commission,
      fees: fees ?? this.fees,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Transaction.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return Transaction(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      type: TransactionType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toInt(),
      phoneNumber: map['phoneNumber'] as String,
      date: DateTime.parse(map['date'] as String),
      status: TransactionStatus.values.byName(map['status'] as String),
      customerName: map['customerName'] as String?,
      commission: (map['commission'] as num?)?.toInt(),
      fees: (map['fees'] as num?)?.toInt(),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String?,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'type': type.name,
      'amount': amount,
      'phoneNumber': phoneNumber,
      'date': date.toIso8601String(),
      'status': status.name,
      'customerName': customerName,
      'commission': commission,
      'fees': fees,
      'reference': reference,
      'notes': notes,
      'createdBy': createdBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isCashIn => type == TransactionType.cashIn;
  bool get isCashOut => type == TransactionType.cashOut;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isFailed => status == TransactionStatus.failed;
}

enum TransactionType { cashIn, cashOut }

enum TransactionStatus { pending, completed, failed }

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

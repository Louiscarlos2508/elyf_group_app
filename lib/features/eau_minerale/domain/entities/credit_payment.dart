/// Represents a payment made against a credit sale.
class CreditPayment {
  const CreditPayment({
    required this.id,
    required this.enterpriseId,
    required this.saleId,
    required this.amount,
    required this.date,
    this.notes,
    this.cashAmount = 0,
    this.orangeMoneyAmount = 0,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String saleId;
  final int amount;
  final DateTime date;
  final String? notes;
  final int cashAmount;
  final int orangeMoneyAmount;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  bool get isDeleted => deletedAt != null;

  CreditPayment copyWith({
    String? id,
    String? enterpriseId,
    String? saleId,
    int? amount,
    DateTime? date,
    String? notes,
    int? cashAmount,
    int? orangeMoneyAmount,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CreditPayment(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      saleId: saleId ?? this.saleId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      cashAmount: cashAmount ?? this.cashAmount,
      orangeMoneyAmount: orangeMoneyAmount ?? this.orangeMoneyAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory CreditPayment.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return CreditPayment(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      saleId: map['saleId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      cashAmount: (map['cashAmount'] as num?)?.toInt() ?? 0,
      orangeMoneyAmount: (map['orangeMoneyAmount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'saleId': saleId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'cashAmount': cashAmount,
      'orangeMoneyAmount': orangeMoneyAmount,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

/// Represents a credit entry for a customer.
class CustomerCredit {
  const CustomerCredit({
    required this.id,
    required this.enterpriseId,
    required this.saleId,
    required this.amount,
    required this.amountPaid,
    required this.date,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final String saleId;
  final int amount;
  final int amountPaid;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  int get remainingAmount => amount - amountPaid;
  bool get isFullyPaid => remainingAmount == 0;
  bool get isDeleted => deletedAt != null;

  CustomerCredit copyWith({
    String? id,
    String? enterpriseId,
    String? saleId,
    int? amount,
    int? amountPaid,
    DateTime? date,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CustomerCredit(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      saleId: saleId ?? this.saleId,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory CustomerCredit.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return CustomerCredit(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      saleId: map['saleId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(map['date'] as String),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
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
      'amountPaid': amountPaid,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }
}

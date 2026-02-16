import 'package:equatable/equatable.dart';
import 'sale.dart' show PaymentMethod;

class SupplierSettlement extends Equatable {
  final String id;
  final String enterpriseId;
  final String supplierId;
  final String userId;
  final int amount;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? notes;
  final String? number; // ex: REG-20240212-001
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? hash;
  final String? previousHash;

  const SupplierSettlement({
    required this.id,
    required this.enterpriseId,
    required this.supplierId,
    required this.userId,
    required this.amount,
    this.paymentMethod = PaymentMethod.cash,
    required this.date,
    this.notes,
    this.number,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.hash,
    this.previousHash,
  });

  bool get isDeleted => deletedAt != null;

  SupplierSettlement copyWith({
    String? id,
    String? enterpriseId,
    String? supplierId,
    String? userId,
    int? amount,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? notes,
    String? number,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? hash,
    String? previousHash,
  }) {
    return SupplierSettlement(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      supplierId: supplierId ?? this.supplierId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      number: number ?? this.number,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hash: hash ?? this.hash,
      previousHash: previousHash ?? this.previousHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'supplierId': supplierId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'number': number,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'hash': hash,
      'previousHash': previousHash,
    };
  }

  factory SupplierSettlement.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return SupplierSettlement(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      supplierId: map['supplierId'] as String,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num).toInt(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['paymentMethod'] as String? ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      number: map['number'] as String?,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      hash: map['hash'] as String?,
      previousHash: map['previousHash'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        enterpriseId,
        supplierId,
        userId,
        amount,
        paymentMethod,
        date,
        notes,
        number,
        deletedAt,
        deletedBy,
        createdAt,
        updatedAt,
        hash,
        previousHash,
      ];
}
